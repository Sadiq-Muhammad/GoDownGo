package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"golang.org/x/crypto/ssh"
	"gopkg.in/yaml.v3"
)

type Server struct {
	Host     string `yaml:"host"`
	Username string `yaml:"username"`
	Password string `yaml:"password"`
	Command  string `yaml:"command"`
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
	err = yaml.Unmarshal(data, &config)
	if err != nil {
		return nil, err
	}
	return config.Servers, nil
}

func executeSSHCommand(server Server) string {
	config := &ssh.ClientConfig{
		User: server.Username,
		Auth: []ssh.AuthMethod{
			ssh.Password(server.Password),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         5 * time.Second,
	}

	conn, err := ssh.Dial("tcp", server.Host+":22", config)
	if err != nil {
		return fmt.Sprintf("Failed to connect: %v", err)
	}
	defer conn.Close()

	session, err := conn.NewSession()
	if err != nil {
		return fmt.Sprintf("Failed to create session: %v", err)
	}
	defer session.Close()

	output, err := session.CombinedOutput(server.Command)
	if err != nil {
		return fmt.Sprintf("Command execution error: %v", err)
	}

	return string(output)
}

func main() {
	yamlFile := flag.String("file", "servers.yaml", "Path to the YAML file")
	hostFilter := flag.String("host", "", "Execute command only on this host")

	flag.Parse()

	servers, err := loadServers(*yamlFile)
	if err != nil {
		log.Fatalf("Error loading servers: %v", err)
	}

	for _, server := range servers {
		if *hostFilter != "" && server.Host != *hostFilter {
			continue
		}

		fmt.Printf("Connecting to %s...\n", server.Host)
		result := executeSSHCommand(server)
		fmt.Printf("Output from %s:\n%s\n", server.Host, result)
		fmt.Println(strings.Repeat("-", 50))
	}
}
