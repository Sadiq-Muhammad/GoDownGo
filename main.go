package main

import (
	"fmt"
	"strings"
	"time"

	"golang.org/x/crypto/ssh"
)

// Server structure
type Server struct {
	host     string
	username string
	password string
	command  string
}

// executeSSHCommand connects to the server and executes a command
func executeSSHCommand(server Server) string {
	config := &ssh.ClientConfig{
		User: server.username,
		Auth: []ssh.AuthMethod{
			ssh.Password(server.password), // Password authentication
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(), // Skip host key verification (not recommended for production)
		Timeout:         5 * time.Second,             // Connection timeout
	}

	// Connect to SSH server
	conn, err := ssh.Dial("tcp", server.host+":22", config)
	if err != nil {
		return fmt.Sprintf("Failed to connect: %v", err)
	}
	defer conn.Close()

	// Create a session
	session, err := conn.NewSession()
	if err != nil {
		return fmt.Sprintf("Failed to create session: %v", err)
	}
	defer session.Close()

	// Run command
	output, err := session.CombinedOutput(server.command)
	if err != nil {
		return fmt.Sprintf("Command execution error: %v", err)
	}

	return string(output)
}

func main() {
	WIN_COMMAND := "dir" // Windows equivalent of 'ls'

	servers := []Server{
		{host: "127.0.0.1", username: "Sadiq", password: "dorimefa@127720@0783", command: WIN_COMMAND},
		// Add more servers here
	}

	for _, server := range servers {
		fmt.Printf("Connecting to %s...\n", server.host)
		result := executeSSHCommand(server)
		fmt.Printf("Output from %s:\n%s\n", server.host, result)
		fmt.Println(strings.Repeat("-", 50))
	}
}
