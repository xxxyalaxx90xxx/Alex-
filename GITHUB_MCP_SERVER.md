# Local GitHub MCP Server

The GitHub MCP (Model Context Protocol) Server enables AI-powered tools to interact with GitHub repositories, issues, pull requests, and workflows through a standardized protocol.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Handling PATs Securely](#handling-pats-securely)
- [GitHub Enterprise Server and Enterprise Cloud](#github-enterprise-server-and-enterprise-cloud-with-data-residency-ghecom)
- [Installation](#installation)
  - [VS Code](#install-in-github-copilot-on-vs-code)
  - [Other IDEs](#install-in-github-copilot-on-other-ides-jetbrains-visual-studio-eclipse-etc)
- [Configuration Options](#configuration-options)
- [Troubleshooting](#troubleshooting)

## Prerequisites

To run the server in a container, you will need to have Docker installed.

1. **Install Docker**: Download and install Docker from [docker.com](https://www.docker.com/get-started)
2. **Ensure Docker is running**: The Docker daemon must be active before using the MCP server
3. **Docker Image**: The image is available at `ghcr.io/github/github-mcp-server` and is public
   - If you encounter pull errors, you may have an expired token. Run `docker logout ghcr.io` to resolve this
4. **GitHub Personal Access Token (PAT)**: Create a token with appropriate permissions
   - Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
   - Select the permissions you're comfortable granting to your AI tools
   - For more information, see [GitHub's documentation on access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

## Handling PATs Securely

**Important Security Practices:**

- **Never commit your PAT to version control**
- Store your PAT in environment variables or secure credential managers
- Use input prompts in your IDE configuration to avoid hardcoding tokens
- Regularly rotate your PATs and revoke unused tokens
- Grant only the minimum required permissions for your use case

### Recommended PAT Permissions

For typical AI tool usage, consider granting:
- `repo` - Full control of private repositories (if needed)
- `read:org` - Read org and team membership
- `workflow` - Update GitHub Action workflows (if needed)
- `read:packages` - Download packages from GitHub Package Registry

Adjust permissions based on your specific requirements.

## GitHub Enterprise Server and Enterprise Cloud with data residency (ghe.com)

The `--gh-host` flag and the `GITHUB_HOST` environment variable can be used to set the hostname for GitHub Enterprise Server or GitHub Enterprise Cloud with data residency.

### GitHub Enterprise Server

For GitHub Enterprise Server, **prefix the hostname with the `https://` URI scheme**, as it otherwise defaults to `http://`, which GitHub Enterprise Server does not support.

**Example:**
```bash
GITHUB_HOST="https://github.yourcompany.com"
```

### GitHub Enterprise Cloud with Data Residency

For GitHub Enterprise Cloud with data residency, use `https://YOURSUBDOMAIN.ghe.com` as the hostname.

**Example:**
```bash
GITHUB_HOST="https://yourorg.ghe.com"
```

### Configuration Example

```json
{
  "github": {
    "command": "docker",
    "args": [
      "run",
      "-i",
      "--rm",
      "-e",
      "GITHUB_PERSONAL_ACCESS_TOKEN",
      "-e",
      "GITHUB_HOST",
      "ghcr.io/github/github-mcp-server"
    ],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "${input:github_token}",
      "GITHUB_HOST": "https://<your GHES or ghe.com domain name>"
    }
  }
}
```

## Installation

### Install in GitHub Copilot on VS Code

#### Quick Installation

For VS Code users, you can use one-click install buttons (if supported by your VS Code version):

- **[Install with Docker in VS Code](vscode://github.copilot-mcp-server/install?name=github&image=ghcr.io/github/github-mcp-server)**
- **[Install with Docker in VS Code Insiders](vscode-insiders://github.copilot-mcp-server/install?name=github&image=ghcr.io/github/github-mcp-server)**

> **Note**: If the one-click install links don't work in your VS Code version, use the manual installation method below.

Once you complete the installation flow:
1. Toggle **Agent mode** (located by the Copilot Chat text input)
2. The server will start automatically

For more information about using MCP server tools, see [VS Code's agent mode documentation](https://code.visualstudio.com/docs/copilot/copilot-extensibility-overview).

#### Manual Installation for VS Code

Alternatively, you can manually configure the MCP server in VS Code:

1. Open your VS Code settings
2. Navigate to MCP settings
3. Add the GitHub MCP server configuration:

```json
{
  "mcp": {
    "inputs": [
      {
        "type": "promptString",
        "id": "github_token",
        "description": "GitHub Personal Access Token",
        "password": true
      }
    ],
    "servers": {
      "github": {
        "command": "docker",
        "args": [
          "run",
          "-i",
          "--rm",
          "-e",
          "GITHUB_PERSONAL_ACCESS_TOKEN",
          "ghcr.io/github/github-mcp-server"
        ],
        "env": {
          "GITHUB_PERSONAL_ACCESS_TOKEN": "${input:github_token}"
        }
      }
    }
  }
}
```

### Install in GitHub Copilot on other IDEs (JetBrains, Visual Studio, Eclipse, etc.)

For JetBrains IDEs (IntelliJ IDEA, PyCharm, WebStorm, etc.), Visual Studio, Eclipse, and other supported IDEs:

1. Locate your IDE's MCP settings configuration file
2. Add the following JSON block to your MCP settings:

```json
{
  "mcp": {
    "inputs": [
      {
        "type": "promptString",
        "id": "github_token",
        "description": "GitHub Personal Access Token",
        "password": true
      }
    ],
    "servers": {
      "github": {
        "command": "docker",
        "args": [
          "run",
          "-i",
          "--rm",
          "-e",
          "GITHUB_PERSONAL_ACCESS_TOKEN",
          "ghcr.io/github/github-mcp-server"
        ],
        "env": {
          "GITHUB_PERSONAL_ACCESS_TOKEN": "${input:github_token}"
        }
      }
    }
  }
}
```

3. Save the configuration file
4. Restart your IDE if necessary
5. When prompted, enter your GitHub Personal Access Token

## Configuration Options

Optionally, you can customize the MCP server behavior with additional environment variables and arguments:

### Environment Variables

The GitHub MCP Server supports the following environment variables:

- `GITHUB_PERSONAL_ACCESS_TOKEN` (required): Your GitHub Personal Access Token with appropriate permissions
- `GITHUB_HOST` (optional): Custom GitHub hostname for Enterprise Server or GHE Cloud (default: `https://github.com`)

For the latest information on supported configuration options, refer to the [GitHub MCP Server repository](https://github.com/github/github-mcp-server).

### Advanced Configuration Example

Example showing GitHub Enterprise Server configuration:

```json
{
  "mcp": {
    "inputs": [
      {
        "type": "promptString",
        "id": "github_token",
        "description": "GitHub Personal Access Token",
        "password": true
      }
    ],
    "servers": {
      "github": {
        "command": "docker",
        "args": [
          "run",
          "-i",
          "--rm",
          "-e",
          "GITHUB_PERSONAL_ACCESS_TOKEN",
          "-e",
          "GITHUB_HOST",
          "ghcr.io/github/github-mcp-server"
        ],
        "env": {
          "GITHUB_PERSONAL_ACCESS_TOKEN": "${input:github_token}",
          "GITHUB_HOST": "https://github.yourcompany.com"
        }
      }
    }
  }
}
```

## Troubleshooting

### Common Issues

#### Docker Image Pull Fails

**Problem**: Error pulling `ghcr.io/github/github-mcp-server`

**Solution**:
```bash
# Logout from GitHub Container Registry
docker logout ghcr.io

# Pull the image again
docker pull ghcr.io/github/github-mcp-server
```

#### Authentication Errors

**Problem**: "Bad credentials" or "401 Unauthorized" errors

**Solutions**:
1. Verify your PAT is correct and not expired
2. Check that your PAT has the required permissions
3. Ensure the PAT is properly passed to the Docker container
4. Regenerate your PAT if necessary

#### Connection Issues with GitHub Enterprise

**Problem**: Cannot connect to GitHub Enterprise Server

**Solutions**:
1. Ensure you're using the `https://` prefix in `GITHUB_HOST`
2. Verify the hostname is correct
3. Check network connectivity to your Enterprise Server
4. Confirm your firewall allows the connection

#### Server Not Starting

**Problem**: MCP server fails to start

**Solutions**:
1. Check Docker is running: `docker ps`
2. Verify the Docker image is available: `docker images | grep github-mcp-server`
3. Check IDE logs for error messages
4. Ensure no port conflicts exist
5. Try running the Docker command manually to see detailed errors:
   ```bash
   # Set your token in an environment variable first (won't be logged in history)
   export GITHUB_PERSONAL_ACCESS_TOKEN="your_token"
   docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server
   ```

### Getting Help

- **GitHub MCP Server Issues**: [github.com/github/github-mcp-server/issues](https://github.com/github/github-mcp-server/issues)
- **VS Code Copilot Documentation**: [code.visualstudio.com/docs/copilot](https://code.visualstudio.com/docs/copilot)
- **Docker Documentation**: [docs.docker.com](https://docs.docker.com)

## Additional Resources

- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
