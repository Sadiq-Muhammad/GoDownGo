package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"os"
	"strings"
	"sync"
	"syscall"
	"time"

	"golang.org/x/crypto/ssh"
	"golang.org/x/term"
	"gopkg.in/yaml.v3"
)

// Colors for terminal output
const (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorGreen  = "\033[32m"
	colorYellow = "\033[33m"
	colorBlue   = "\033[34m"
)

// Server struct for YAML parsing
type Server struct {
	Host     string   `yaml:"host"`
	Port     string   `yaml:"port,omitempty"`
	Username string   `yaml:"username"`
	Password string   `yaml:"password,omitempty"`
	KeyFile  string   `yaml:"key_file,omitempty"`
	Commands []string `yaml:"commands"`
}

// Config struct for YAML parsing
type Config struct {
	Servers []Server `yaml:"servers"`
}

// Load YAML configuration file
func loadConfig(filePath string) (*Config, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	return &config, nil
}

// Get SSH configuration with fallback for legacy devices
func getSSHConfig(server Server, fallback bool) (*ssh.ClientConfig, error) {
	var auth []ssh.AuthMethod

	// Handle password-based or key-based authentication
	if server.KeyFile != "" {
		key, err := os.ReadFile(server.KeyFile)
		if err != nil {
			return nil, fmt.Errorf("failed to read key file: %w", err)
		}
		signer, err := ssh.ParsePrivateKey(key)
		if err != nil {
			return nil, fmt.Errorf("failed to parse key: %w", err)
		}
		auth = append(auth, ssh.PublicKeys(signer))
	} else {
		if server.Password == "" {
			fmt.Printf("%sEnter password for %s@%s: %s", colorYellow, server.Username, server.Host, colorReset)
			bytePassword, err := term.ReadPassword(int(syscall.Stdin))
			fmt.Println()
			if err != nil {
				return nil, fmt.Errorf("failed to read password: %w", err)
			}
			server.Password = string(bytePassword)
		}
		auth = append(auth, ssh.Password(server.Password))
	}

	// Algorithm configuration
	defaultCiphers := []string{"aes128-ctr", "aes192-ctr", "aes256-ctr"}
	defaultKex := []string{"curve25519-sha256", "ecdh-sha2-nistp384", "diffie-hellman-group14-sha256"}
	fallbackCiphers := []string{"aes128-cbc", "aes256-cbc", "aes128-ctr", "aes256-ctr"}
	fallbackKex := []string{"diffie-hellman-group1-sha1", "diffie-hellman-group14-sha1"}

	ciphers := defaultCiphers
	kex := defaultKex
	if fallback {
		ciphers = fallbackCiphers
		kex = fallbackKex
	}

	return &ssh.ClientConfig{
		User:            server.Username,
		Auth:            auth,
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         30 * time.Second,
		Config: ssh.Config{
			Ciphers:      ciphers,
			KeyExchanges: kex,
		},
	}, nil
}

// Connect with modern algorithms first, then fallback to legacy
func connectWithFallback(server Server) (*ssh.Client, error) {
	port := server.Port
	if port == "" {
		port = "22"
	}
	address := fmt.Sprintf("%s:%s", server.Host, port)

	// First attempt with modern algorithms
	config, err := getSSHConfig(server, false)
	if err != nil {
		return nil, err
	}

	fmt.Printf("%sConnecting to %s...%s\n", colorBlue, address, colorReset)
	conn, err := ssh.Dial("tcp", address, config)
	if err == nil {
		fmt.Printf("%sConnected to %s (modern algorithms)%s\n", colorGreen, address, colorReset)
		return conn, nil
	}

	// Fallback to legacy algorithms
	fmt.Printf("%sRetrying %s with legacy algorithms...%s\n", colorYellow, address, colorReset)
	config, err = getSSHConfig(server, true)
	if err != nil {
		return nil, err
	}

	conn, err = ssh.Dial("tcp", address, config)
	if err != nil {
		return nil, fmt.Errorf("connection failed after fallback: %w", err)
	}
	fmt.Printf("%sConnected to %s (legacy algorithms)%s\n", colorGreen, address, colorReset)
	return conn, nil
}

// Execute commands over SSH
func executeSSHCommands(ctx context.Context, server Server, wg *sync.WaitGroup, logFile *os.File, logMutex *sync.Mutex) {
	defer wg.Done()

	select {
	case <-ctx.Done():
		fmt.Printf("%sCancelled connection to %s%s\n", colorYellow, server.Host, colorReset)
		return
	default:
	}

	conn, err := connectWithFallback(server)
	if err != nil {
		logError(fmt.Sprintf("Connection failed to %s", server.Host), err)
		return
	}
	defer conn.Close()

	fmt.Printf("%sExecuting commands on %s...%s\n", colorBlue, server.Host, colorReset)

	for _, cmd := range server.Commands {
		session, err := conn.NewSession()
		if err != nil {
			logError(fmt.Sprintf("Session failed on %s", server.Host), err)
			continue
		}
		// If the command uses sudo with -S (to read from stdin), set up the input pipe.
		if strings.Contains(cmd, "sudo -S") {
			stdin, err := session.StdinPipe()
			if err != nil {
				logError(fmt.Sprintf("Failed to obtain StdinPipe for sudo on %s", server.Host), err)
				session.Close()
				continue
			}
			go func() {
				// Write the SSH login password as the sudo password.
				if server.Password != "" {
					io.WriteString(stdin, server.Password+"\n")
				}
			}()
		}

		output, err := session.CombinedOutput(cmd)
		if err != nil {
			logError(fmt.Sprintf("Command failed on %s: %s", server.Host, cmd), err)
		} else {
			fmt.Printf("%sOutput from %s:\n%s%s\n", colorGreen, server.Host, colorReset, string(output))
		}

		if logFile != nil {
			logMutex.Lock()
			_, err = logFile.WriteString(fmt.Sprintf("[%s] %s\n%s\n", server.Host, cmd, output))
			logMutex.Unlock()
			if err != nil {
				logError("Failed to write to log", err)
			}
		}
		session.Close()
	}
}

// Log errors
func logError(message string, err error) {
	fmt.Printf("%s[ERROR] %s: %v%s\n", colorRed, message, err, colorReset)
}

// Main function
func main() {
	var (
		configFile = flag.String("f", "", "Path to configuration YAML file (required)")
		helpFlag   = flag.Bool("h", false, "Show help message")
		logFile    = flag.String("log", "", "Enable logging to specified file")
	)

	flag.Parse()

	if *helpFlag {
		fmt.Printf("Usage: %s -f config.yaml [-log logfile.txt]\n", os.Args[0])
		flag.PrintDefaults()
		os.Exit(0)
	}

	if *configFile == "" {
		fmt.Printf("%sError: Config file is required. Use -f to specify.%s\n", colorRed, colorReset)
		os.Exit(1)
	}

	config, err := loadConfig(*configFile)
	if err != nil {
		logError("Failed to load config", err)
		os.Exit(1)
	}

	var logHandle *os.File
	if *logFile != "" {
		logHandle, err = os.Create(*logFile)
		if err != nil {
			logError("Failed to create log file", err)
			os.Exit(1)
		}
		defer logHandle.Close()
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	var wg sync.WaitGroup
	var logMutex sync.Mutex

	for _, server := range config.Servers {
		wg.Add(1)
		go executeSSHCommands(ctx, server, &wg, logHandle, &logMutex)
	}

	wg.Wait()
	fmt.Println(colorGreen + "All operations completed!" + colorReset)
}
