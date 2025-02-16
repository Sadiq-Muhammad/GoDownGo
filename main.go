package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"sync"

	"github.com/Sadiq-Muhammad/gxsh/internal/config"
	"github.com/Sadiq-Muhammad/gxsh/internal/ssh"
	"github.com/Sadiq-Muhammad/gxsh/internal/utils"
)

func main() {
	var (
		configFile = flag.String("f", "", "Path to configuration YAML file (required)")
		helpFlag   = flag.Bool("h", false, "Show help message")
		logFile    = flag.String("log", "", "Enable logging to specified file")
	)

	flag.Parse()
	validateFlags(*helpFlag, *configFile)

	cfg := loadConfig(*configFile)
	logger := setupLogger(*logFile)
	defer logger.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	runCommands(ctx, cfg.Servers, logger)
}

func validateFlags(help bool, configFile string) {
	if help {
		printHelp()
		os.Exit(0)
	}
	if configFile == "" {
		exitWithError("Config file is required. Use -f to specify.")
	}
}

func printHelp() {
	fmt.Printf("Usage: %s -f config.yaml [-log logfile.txt]\n", os.Args[0])
	flag.PrintDefaults()
}

func exitWithError(message string) {
	fmt.Printf("%s%s%s\n", utils.ColorRed, message, utils.ColorReset)
	os.Exit(1)
}

func loadConfig(path string) *config.Config {
	cfg, err := config.Load(path)
	if err != nil {
		exitWithError(fmt.Sprintf("Failed to load config: %v", err))
	}
	return cfg
}

func setupLogger(path string) *utils.Logger {
	logger, err := utils.NewLogger(path)
	if err != nil {
		exitWithError(fmt.Sprintf("Failed to initialize logger: %v", err))
	}
	return logger
}

func runCommands(ctx context.Context, servers []config.Server, logger *utils.Logger) {
	var wg sync.WaitGroup

	for _, server := range servers {
		wg.Add(1)
		go func(s config.Server) {
			defer wg.Done()
			client := ssh.NewClient(s)
			if err := client.ExecuteCommands(ctx, logger); err != nil {
				utils.LogError("Execution failed", err)
			}
		}(server)
	}

	wg.Wait()
	fmt.Println(utils.ColorGreen + "All operations completed!" + utils.ColorReset)
}
