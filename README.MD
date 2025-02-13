# GoDo

A command-line tool written in Go that reads server configurations from a YAML file and executes specified SSH commands on them.

## Features
- Load server details (host, username, password, and command) from an external YAML file.
- Securely connect to remote servers via SSH.
- Execute commands on multiple servers.
- Filter execution to a specific host using a command-line argument.

## Requirements
- Go 1.16 or later
- OpenSSH installed on the client machine
- A YAML file containing server details

## Installation
1. Clone this repository:
   ```sh
   git clone https://github.com/yourusername/ssh-command-executor.git
   cd ssh-command-executor
   ```
2. Install dependencies:
   ```sh
   go mod tidy
   ```
3. Build the binary:
   ```sh
   go build -o ssh-exec
   ```

## Usage
### Run the tool with a YAML configuration file:
```sh
./ssh-exec -file servers.yaml
```

### Run for a specific host:
```sh
./ssh-exec -file servers.yaml -host 192.168.1.100
```

## YAML Configuration
Create a `servers.yaml` file in the following format:
```yaml
servers:
  - host: "192.168.1.100"
    username: "user1"
    password: "password1"
    command: "uptime"
  - host: "192.168.1.101"
    username: "user2"
    password: "password2"
    command: "df -h"
```

## Security Considerations
- Avoid storing plain-text passwords in YAML files; consider using SSH keys.
- Use a vault or environment variables for sensitive credentials.

## License
This project is licensed under the MIT License.

## Contributions
Pull requests and improvements are welcome! Feel free to open an issue for any feature requests or bugs.

## Author
Sadiq Muhammad