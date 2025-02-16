package ssh

import (
	"fmt"
	"os"
	"syscall"
	"time"

	"github.com/Sadiq-Muhammad/gxsh/internal/utils"
	"golang.org/x/crypto/ssh"
	"golang.org/x/term"
)

func (c *Client) connect(fallback bool) (*ssh.Client, error) {
	auth, err := c.getAuthMethods()
	if err != nil {
		return nil, err
	}

	config := c.createSSHConfig(auth, fallback)
	address := fmt.Sprintf("%s:%s", c.server.Host, c.server.PortOrDefault())

	return ssh.Dial("tcp", address, config)
}

func (c *Client) getAuthMethods() ([]ssh.AuthMethod, error) {
	if c.server.KeyFile != "" {
		return c.handleKeyAuth()
	}
	return c.handlePasswordAuth()
}

func (c *Client) handleKeyAuth() ([]ssh.AuthMethod, error) {
	key, err := os.ReadFile(c.server.KeyFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read key file: %w", err)
	}

	signer, err := ssh.ParsePrivateKey(key)
	if err != nil {
		return nil, fmt.Errorf("failed to parse key: %w", err)
	}

	return []ssh.AuthMethod{ssh.PublicKeys(signer)}, nil
}

func (c *Client) handlePasswordAuth() ([]ssh.AuthMethod, error) {
	if c.server.Password == "" {
		fmt.Printf("%sEnter password for %s@%s: %s",
			utils.ColorYellow, c.server.Username, c.server.Host, utils.ColorReset)
		bytePassword, err := term.ReadPassword(int(syscall.Stdin))
		fmt.Println()
		if err != nil {
			return nil, fmt.Errorf("failed to read password: %w", err)
		}
		c.server.Password = string(bytePassword)
	}
	return []ssh.AuthMethod{ssh.Password(c.server.Password)}, nil
}

func (c *Client) createSSHConfig(auth []ssh.AuthMethod, fallback bool) *ssh.ClientConfig {
	config := &ssh.ClientConfig{
		User:            c.server.Username,
		Auth:            auth,
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         30 * time.Second,
	}

	if fallback {
		config.Config = ssh.Config{
			Ciphers: []string{
				"aes128-cbc", "aes256-cbc", "aes128-ctr", "aes256-ctr",
			},
			KeyExchanges: []string{
				"diffie-hellman-group1-sha1",
				"diffie-hellman-group14-sha1",
			},
		}
		config.HostKeyAlgorithms = append(config.HostKeyAlgorithms, ssh.KeyAlgoDSA)
	} else {
		config.Config = ssh.Config{
			Ciphers: []string{
				"aes128-ctr", "aes192-ctr", "aes256-ctr",
			},
			KeyExchanges: []string{
				"curve25519-sha256",
				"ecdh-sha2-nistp384",
				"diffie-hellman-group14-sha256",
			},
		}
	}

	return config
}
