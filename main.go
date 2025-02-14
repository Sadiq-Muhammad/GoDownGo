package main

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"golang.org/x/crypto/ssh"
	"golang.org/x/term"
	"gopkg.in/yaml.v3"
)

// ANSI color codes
const (
	colorRed    = "\033[31m"
	colorGreen  = "\033[32m"
	colorBlue   = "\033[34m"
	colorYellow = "\033[33m"
	colorReset  = "\033[0m"
)

type Server struct {
	Host     string   `yaml:"host"`
	Username string   `yaml:"username"`
	Password string   `yaml:"password,omitempty"`
	KeyFile  string   `yaml:"key_file,omitempty"`
	Commands []string `yaml:"commands"`
}

type Config struct {
	Servers []Server `yaml:"servers"`
}

// loadServers validates and loads server configurations from YAML
func loadServers(filename string) ([]Server, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("config read error: %w", err)
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("yaml parse error: %w", err)
	}

	for i, server := range config.Servers {
		if server.Host == "" || server.Username == "" || len(server.Commands) == 0 {
			return nil, fmt.Errorf("invalid server configuration at index %d: missing required fields", i)
		}
	}

	return config.Servers, nil
}

// getSSHConfig creates SSH client configuration with secure defaults
func getSSHConfig(server Server) (*ssh.ClientConfig, error) {
	var auth []ssh.AuthMethod

	switch {
	case server.KeyFile != "":
		key, err := os.ReadFile(server.KeyFile)
		if err != nil {
			return nil, fmt.Errorf("key read failed: %w", err)
		}

		signer, err := ssh.ParsePrivateKey(key)
		if err != nil {
			return nil, fmt.Errorf("key parse failed: %w", err)
		}
		auth = append(auth, ssh.PublicKeys(signer))
	default:
		if server.Password == "" {
			fmt.Printf("%sEnter password for %s@%s:%s ", colorYellow, server.Username, server.Host, colorReset)
			bytePassword, err := term.ReadPassword(int(os.Stdin.Fd()))
			fmt.Println()
			if err != nil {
				return nil, fmt.Errorf("password input failed: %w", err)
			}
			server.Password = string(bytePassword)
		}
		auth = append(auth, ssh.Password(server.Password))
	}

	return &ssh.ClientConfig{
		User:            server.Username,
		Auth:            auth,
		HostKeyCallback: ssh.InsecureIgnoreHostKey(), // Warning: Insecure for production use
		Timeout:         30 * time.Second,
	}, nil
}

func executeSSHCommands(ctx context.Context, server Server, wg *sync.WaitGroup, logFile *os.File, logMutex *sync.Mutex) {
	defer wg.Done()

	select {
	case <-ctx.Done():
		fmt.Printf("%sCancelled connection to %s%s\n", colorYellow, server.Host, colorReset)
		return
	default:
	}

	fmt.Printf("%sConnecting to %s...%s\n", colorBlue, server.Host, colorReset)

	config, err := getSSHConfig(server)
	if err != nil {
		logError(fmt.Sprintf("Configuration error for %s", server.Host), err)
		return
	}

	conn, err := ssh.Dial("tcp", server.Host+":22", config)
	if err != nil {
		logError(fmt.Sprintf("Connection failed to %s", server.Host), err)
		return
	}
	defer conn.Close()

	for _, cmd := range server.Commands {
		session, err := conn.NewSession()
		if err != nil {
			logError(fmt.Sprintf("Session creation failed on %s", server.Host), err)
			continue
		}

		var output bytes.Buffer
		session.Stdout = &output
		session.Stderr = &output

		err = session.Run(cmd)
		session.Close() // Immediate cleanup

		if err != nil {
			logError(fmt.Sprintf("Command failed on %s: %s", server.Host, cmd), err)
		} else {
			fmt.Printf("%sOutput from %s:%s\n%s\n", colorGreen, server.Host, colorReset, output.String())
		}

		if logFile != nil {
			logMutex.Lock()
			_, err = logFile.WriteString(fmt.Sprintf("[%s] %s\n%s\n", server.Host, cmd, output.String()))
			logMutex.Unlock()

			if err != nil {
				logError("Log write failed", err)
			}
		}
	}
}

func logError(context string, err error) {
	fmt.Printf("%s%s: %v%s\n", colorRed, context, err, colorReset)
}

func main() {
	var (
		yamlFile    = flag.String("file", "servers.yaml", "path to servers configuration file")
		logFilePath = flag.String("log", "", "path to output log file")
		hostFilter  = flag.String("host", "", "filter servers by hostname")
		helpFlag    = flag.Bool("help", false, "show help message")
	)

	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "GoDo\n\nUsage:\n")
		flag.PrintDefaults()
		fmt.Fprintln(flag.CommandLine.Output(), "\nExample:")
		fmt.Fprintf(flag.CommandLine.Output(), "godo -file config.yaml -log results.log -host web01\n")
	}

	flag.Parse()

	if *helpFlag {
		flag.Usage()
		return
	}

	servers, err := loadServers(*yamlFile)
	if err != nil {
		log.Fatalf("%sFatal error: %v%s", colorRed, err, colorReset)
	}

	// Apply host filter
	filtered := servers[:0]
	for _, s := range servers {
		if *hostFilter == "" || s.Host == *hostFilter {
			filtered = append(filtered, s)
		}
	}

	if len(filtered) == 0 {
		log.Fatalf("%sNo servers matching filter '%s'%s", colorRed, *hostFilter, colorReset)
	}

	// Setup logging
	var logFile *os.File
	if *logFilePath != "" {
		logFile, err = os.Create(*logFilePath)
		if err != nil {
			log.Fatalf("%sLog creation failed: %v%s", colorRed, err, colorReset)
		}
		defer logFile.Close()
	}

	// Context and signal handling
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-sigChan
		fmt.Printf("\n%sReceived interrupt, shutting down...%s\n", colorYellow, colorReset)
		cancel()
		os.Exit(1)
	}()

	// Execution pipeline
	var (
		wg       sync.WaitGroup
		logMutex sync.Mutex
	)

	for _, server := range filtered {
		wg.Add(1)
		go executeSSHCommands(ctx, server, &wg, logFile, &logMutex)
	}

	wg.Wait()
	fmt.Printf("%sAll operations completed%s\n", colorGreen, colorReset)
}
