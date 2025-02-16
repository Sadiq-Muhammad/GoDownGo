package ssh

import (
	"context"
	"fmt"
	"io"
	"strings"
	"sync"

	"github.com/Sadiq-Muhammad/gxsh/internal/config"
	"github.com/Sadiq-Muhammad/gxsh/internal/utils"
	"golang.org/x/crypto/ssh"
)

type Client struct {
	server config.Server
}

func NewClient(server config.Server) *Client {
	return &Client{server: server}
}

func (c *Client) ExecuteCommands(ctx context.Context, logger *utils.Logger) error {
	conn, err := c.connectWithFallback()
	if err != nil {
		return fmt.Errorf("connection failed to %s: %w", c.server.Host, err)
	}
	defer conn.Close()

	fmt.Printf("%sExecuting commands on %s...%s\n", utils.ColorBlue, c.server.Host, utils.ColorReset)

	var wg sync.WaitGroup
	for _, cmd := range c.server.Commands {
		wg.Add(1)
		go func(command string) {
			defer wg.Done()
			c.executeCommand(command, conn, logger)
		}(cmd)
	}
	wg.Wait()
	return nil
}

func (c *Client) executeCommand(cmd string, conn *ssh.Client, logger *utils.Logger) error {
	session, err := conn.NewSession()
	if err != nil {
		return fmt.Errorf("session failed on %s: %w", c.server.Host, err)
	}
	defer session.Close()

	if strings.Contains(cmd, "sudo -S") {
		stdin, err := session.StdinPipe()
		if err != nil {
			return fmt.Errorf("failed to get stdin pipe: %w", err)
		}
		go func() {
			if c.server.Password != "" {
				io.WriteString(stdin, c.server.Password+"\n")
			}
		}()
	}

	output, err := session.CombinedOutput(cmd)
	if err != nil {
		utils.LogError(fmt.Sprintf("Command failed on %s: %s", c.server.Host, cmd), err)
	} else {
		fmt.Printf("%sOutput from %s:\n%s%s\n", utils.ColorGreen, c.server.Host, utils.ColorReset, string(output))
	}

	if logger != nil {
		logger.LogCommand(c.server.Host, cmd, output)
	}
	return nil
}

func (c *Client) connectWithFallback() (*ssh.Client, error) {
	conn, err := c.connect(false) // Try modern config first
	if err == nil {
		return conn, nil
	}

	utils.LogWarning(fmt.Sprintf("Retrying %s with legacy algorithms...", c.server.Host))
	return c.connect(true) // Fallback to legacy config
}
