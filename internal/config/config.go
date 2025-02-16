package config

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

type Server struct {
	Host     string   `yaml:"host"`
	Port     string   `yaml:"port,omitempty"`
	Username string   `yaml:"username"`
	Password string   `yaml:"password,omitempty"`
	KeyFile  string   `yaml:"key_file,omitempty"`
	Commands []string `yaml:"commands"`
}

type Config struct {
	Servers []Server `yaml:"servers"`
}

func Load(filePath string) (*Config, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config: %w", err)
	}

	return &cfg, nil
}

func (s *Server) PortOrDefault() string {
	if s.Port == "" {
		return "22"
	}
	return s.Port
}
