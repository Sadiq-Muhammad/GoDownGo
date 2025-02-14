# GoDo

A command-line tool written in Go that reads server configurations from a YAML file and executes specified SSH commands on them.

## Features
- Securely connect to remote servers via SSH using passwords or SSH keys.
- Execute multiple commands per server.
- Filter execution to a specific host using a command-line argument.
- Expand environment variables within the YAML file.
- Execute commands in parallel for faster processing.
- Support command timeouts to prevent hanging processes.
- Log output to a file for auditing and debugging.

## Requirements
- Go 1.16 or later
- OpenSSH installed on the client machine
- A YAML file containing server details

## Installation
### **Linux & macOS**
Run the installation script:
```sh
curl -sSL https://raw.githubusercontent.com/Sadiq-Muhammad/GoDo/master/install.sh | sudo bash
```

### **Windows**
Run the PowerShell installation script:
```powershell
iwr -useb https://raw.githubusercontent.com/Sadiq-Muhammad/GoDo/master/install.ps1 | iex
```

## Updates
### **Linux & macOS**
Run the installation script:
```sh
curl -sSL https://raw.githubusercontent.com/Sadiq-Muhammad/GoDo/master/update.sh | sudo bash
```

### **Windows**
Run the PowerShell installation script:
```powershell
iwr -useb https://raw.githubusercontent.com/Sadiq-Muhammad/GoDo/master/update.ps1 | iex
```

## Usage
### Run the tool with a YAML configuration file:
```sh
godo -file servers.yaml
```

### Run for a specific host:
```sh
godo -file servers.yaml -host 192.168.1.100
```

### Enable logging:
```sh
godo -file servers.yaml > godo.log
```

## YAML Configuration
Create a `servers.yaml` file in the following format:
```yaml
servers:
  - host: "192.168.1.100"
    username: "user1"
    password: "password1"
    command:
      - "uptime"
      - "df -h"
  - host: "192.168.1.101"
    username: "user2"
    key: "~/.ssh/id_rsa"
    command: "ls -la"
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