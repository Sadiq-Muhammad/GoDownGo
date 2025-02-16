# GXSH : Go Execute SSH

A command-line tool written in Go that reads server configurations from a YAML file and executes specified SSH commands on them.

## Features
- YAML Configuration:
Define multiple servers and commands in an easy-to-edit YAML file, including options for host, port, username, password, key file, and commands.

- Flexible Authentication:
Supports both password-based and key-based SSH authentication. If no password is provided, the tool prompts for it interactively.

- Legacy Device Compatibility:
Automatically attempts connections using modern SSH algorithms first, then gracefully falls back to legacy algorithms when needed, ensuring compatibility with older devices.

- Sudo Command Support:
Detects commands that require elevated privileges (via sudo -S) and automatically pipes the password to execute these commands seamlessly.

- Concurrent Execution:
Leverages goroutines to execute commands concurrently across multiple servers, significantly speeding up operations.

- Robust Logging:
Optionally logs command outputs and errors to a specified file for easy auditing and troubleshooting.

- Color-Coded Terminal Output:
Uses clear, color-coded messages to display connection statuses, command outputs, and error notifications, enhancing readability in the terminal.

- User-Friendly CLI:
Provides intuitive command-line flags for specifying configuration files, enabling logging, and displaying help information.

## You can SSH to...
- Windows
- Linux
- MacOS
- RouterOS (Mikrotik devices)
- AirOS (Ubiquiti)

## Requirements
- OpenSSH installed on the client machine

## Install / Update / Uninstall
### **Linux & macOS**
Run the installation script:
```sh
curl -sSL https://raw.githubusercontent.com/Sadiq-Muhammad/gxsh/master/scripts/gxsh-manager.sh | sudo bash
```

### **Windows**
Run the PowerShell installation script:
```powershell
iwr -useb https://raw.githubusercontent.com/Sadiq-Muhammad/gxsh/master/scripts/gxsh-manager.ps1 | iex
```

## Usage
### Run the tool with a YAML configuration file:
```sh
gxsh -file servers.yaml
```

### Run for a specific host:
```sh
gxsh -f servers.yaml -host 192.168.1.100
```

### Enable logging:
```sh
gxsh -file servers.yaml -log log.txt
```
Or if you don't want the output to be displayed on the terminal use:
```sh
gxsh -file servers.yaml > log.txt
```

## YAML Configuration
Create a `servers.yaml` file in the following format:
```yaml
# config.yaml - SSH Batch Executor Configuration
servers:
  # First server configuration
  - host: "web01.example.com"   # Server hostname or IP (required)
    username: "admin"           # SSH username (required)
    password: "secret123"       # SSH password (optional, not recommended)
    # key_file: "/path/to/key"  # SSH private key path (alternative to password)
    commands:                   # List of commands to execute (required)
      - "uptime"
      - "df -h"
      - "docker ps"
      - "sudo -S apt update"    # To use sudo commands add -S to the sudo

  # Production database server using SSH key
  - host: "db-prod.example.com"
    username: "dba"
    key_file: "~/.ssh/db-prod-key.pem"
    port: 2222                # Set SSH port
    commands:
      - "mysql -e 'SHOW PROCESSLIST;'"
      - "du -sh /var/lib/mysql"
      - "pgrep mysqld"

  # Server that will prompt for password
  - host: "backup.example.com"
    username: "backup-user"
    commands:  # No password/key specified = will prompt at runtime
      - "ls -lh /backups"
      - "free -m"
```

### Using Environment Variables
You can use environment variables for credentials:
```yaml
servers:
  - host: "${SERVER_HOST}"
    username: "${SSH_USER}"
    password: "${SSH_PASS}"
    command: "free -m"
```

## Security Considerations
- Avoid storing plain-text passwords in YAML files; prefer SSH keys.
- Use a vault or environment variables for sensitive credentials.
- Log files should be stored securely to prevent leakage of command outputs.

## License
This project is licensed under the MIT License.

## Contributions
Pull requests and improvements are welcome! Feel free to open an issue for any feature requests or bugs.

## Author
Sadiq Muhammad