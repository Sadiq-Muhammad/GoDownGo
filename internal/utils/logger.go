package utils

import (
	"fmt"
	"io"
	"os"
	"sync"
)

type Logger struct {
	mu     sync.Mutex
	writer io.WriteCloser
}

func NewLogger(filePath string) (*Logger, error) {
	if filePath == "" {
		return &Logger{writer: nil}, nil
	}

	file, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to create log file: %w", err)
	}

	return &Logger{writer: file}, nil
}

func (l *Logger) LogCommand(host, command string, output []byte) {
	if l.writer == nil {
		return
	}

	l.mu.Lock()
	defer l.mu.Unlock()

	entry := fmt.Sprintf("[%s] %s\n%s\n", host, command, output)
	if _, err := l.writer.Write([]byte(entry)); err != nil {
		LogError("Failed to write log entry", err)
	}
}

func (l *Logger) Close() error {
	if l.writer == nil {
		return nil
	}
	return l.writer.Close()
}

func LogError(message string, err error) {
	fmt.Printf("%s[ERROR] %s: %v%s\n", ColorRed, message, err, ColorReset)
}

func LogWarning(message string) {
	fmt.Printf("%s%s%s\n", ColorYellow, message, ColorReset)
}
