package main

import (
	"bytes"
	"flag"
	"fmt"
	"log"
	"os"
	"sync"
	"time"

	"golang.org/x/crypto/ssh"
	"golang.org/x/term"
	"gopkg.in/yaml.v3"
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

func loadServers(filename string) ([]Server, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, err
	}
	return config.Servers, nil
}

func getSSHConfig(server Server) (*ssh.ClientConfig, error) {
	var auth []ssh.AuthMethod
	if server.KeyFile != "" {
		key, err := os.ReadFile(server.KeyFile)
		if err != nil {
			return nil, fmt.Errorf("failed to read SSH key: %v", err)
		}
		signer, err := ssh.ParsePrivateKey(key)
		if err != nil {
			return nil, fmt.Errorf("failed to parse SSH key: %v", err)
		}
		auth = append(auth, ssh.PublicKeys(signer))
	} else {
		if server.Password == "" {
			fmt.Printf("Enter password for %s@%s: ", server.Username, server.Host)
			bytePassword, _ := term.ReadPassword(int(os.Stdin.Fd()))
			fmt.Println()
			server.Password = string(bytePassword)
		}
		auth = append(auth, ssh.Password(server.Password))
	}

	return &ssh.ClientConfig{
		User:            server.Username,
		Auth:            auth,
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         5 * time.Second,
	}, nil
}

func executeSSHCommands(server Server, wg *sync.WaitGroup, logFile *os.File) {
	defer wg.Done()
	fmt.Printf("\033[34mConnecting to %s...\033[0m\n", server.Host)
	config, err := getSSHConfig(server)
	if err != nil {
		fmt.Printf("\033[31mError: %v\033[0m\n", err)
		return
	}

	conn, err := ssh.Dial("tcp", server.Host+":22", config)
	if err != nil {
		fmt.Printf("\033[31mFailed to connect: %v\033[0m\n", err)
		return
	}
	defer conn.Close()

	for _, cmd := range server.Commands {
		session, err := conn.NewSession()
		if err != nil {
			fmt.Printf("\033[31mFailed to create session: %v\033[0m\n", err)
			continue
		}
		defer session.Close()

		var output bytes.Buffer
		session.Stdout = &output
		session.Stderr = &output
		err = session.Run(cmd)
		if err != nil {
			fmt.Printf("\033[31mCommand failed: %v\033[0m\n", err)
		}
		fmt.Printf("\033[32mOutput from %s:\033[0m\n%s\n", server.Host, output.String())
		if logFile != nil {
			logFile.WriteString(fmt.Sprintf("[%s] %s\n%s\n", server.Host, cmd, output.String()))
		}
	}
}

func main() {
	yamlFile := flag.String("file", "servers.yaml", "Path to the YAML file")
	logFilePath := flag.String("log", "", "Path to save command outputs")
	hostFilter := flag.String("host", "", "Execute commands only on this host")
	helpFlag := flag.Bool("help", false, "Display usage information")
	flag.Parse()

	if *helpFlag {
		flag.Usage()
		return
	}

	servers, err := loadServers(*yamlFile)
	if err != nil {
		log.Fatalf("Error loading servers: %v", err)
	}

	var logFile *os.File
	if *logFilePath != "" {
		logFile, err = os.Create(*logFilePath)
		if err != nil {
			log.Fatalf("Failed to create log file: %v", err)
		}
		defer logFile.Close()
	}

	var wg sync.WaitGroup
	for _, server := range servers {
		if *hostFilter != "" && server.Host != *hostFilter {
			continue
		}
		wg.Add(1)
		go executeSSHCommands(server, &wg, logFile)
	}
	wg.Wait()
}
