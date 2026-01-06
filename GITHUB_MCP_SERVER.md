# Local GitHub MCP Server

## Quick Installation Options

- [Docker in VS Code / VS Code Insiders](#install-in-github-copilot-on-vs-code)
- [Docker in Other IDEs](#install-in-github-copilot-on-other-ides-jetbrains-visual-studio-eclipse-etc)

## Overview

The GitHub MCP (Model Context Protocol) server enables AI tools to interact with GitHub APIs through a standardized interface. This guide covers installation using Docker, which provides a consistent and isolated environment for running the MCP server.

## Prerequisites

### 1. Docker Installation

To run the server in a container, you will need to have Docker installed.

Once Docker is installed, you will also need to ensure Docker is running.

**Docker Image**: The Docker image is available at `ghcr.io/github/github-mcp-server`

> **Note**: The image is public. If you encounter errors on pull, you may have an expired token and need to run:
> ```bash
> docker logout ghcr.io
> ```

### 2. GitHub Personal Access Token

Create a [GitHub Personal Access Token (PAT)](https://github.com/settings/tokens) with appropriate permissions.

The MCP server can use many of the GitHub APIs, so enable the permissions that you feel comfortable granting your AI tools. For more information about access tokens, please check out the [GitHub documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).

### Handling PATs Securely

⚠️ **Security Best Practices:**

- Never commit your PAT to version control
- Use environment variables or secure input prompts for token storage
- Rotate your tokens regularly
- Grant only the minimum required permissions
- Consider using fine-grained personal access tokens for better security control

## GitHub Enterprise Server and Enterprise Cloud with Data Residency (ghe.com)

The flag `--gh-host` and the environment variable `GITHUB_HOST` can be used to set the hostname for GitHub Enterprise Server or GitHub Enterprise Cloud with data residency.

- **For GitHub Enterprise Server**: Prefix the hostname with the `https://` URI scheme, as it otherwise defaults to `http://`, which GitHub Enterprise Server does not support.
- **For GitHub Enterprise Cloud with data residency**: Use `https://YOURSUBDOMAIN.ghe.com` as the hostname.

## Installation

### Install in GitHub Copilot on VS Code

Once you have Docker installed and a GitHub Personal Access Token ready, you can configure the MCP server in VS Code.

Toggle Agent mode (located by the Copilot Chat text input) and the server will start once configured.

More about using MCP server tools in [VS Code's agent mode documentation](https://code.visualstudio.com/docs/copilot/copilot-chat).

#### Manual Configuration for VS Code

Add the following JSON block to your VS Code MCP settings (typically in `.vscode/settings.json` or user settings):

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
          "GITHUB_HOST": "https://github.com"
        }
      }
    }
  }
}
```

### Install in GitHub Copilot on Other IDEs (JetBrains, Visual Studio, Eclipse, etc.)

Add the following JSON block to your IDE's MCP settings:

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
          "GITHUB_HOST": "https://github.com"
        }
      }
    }
  }
}
```

> **Note**: For GitHub Enterprise Server or Enterprise Cloud with data residency, update the `GITHUB_HOST` value accordingly. See [Configuration Options](#configuration-options) for examples.

## Configuration Options

### Basic Configuration

The minimal configuration requires:
- Docker command
- Container image: `ghcr.io/github/github-mcp-server`
- GitHub Personal Access Token via environment variable

### Advanced Configuration

#### GitHub Enterprise Server

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
          "GITHUB_HOST": "https://github.your-company.com"
        }
      }
    }
  }
}
```

#### GitHub Enterprise Cloud with Data Residency

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
          "GITHUB_HOST": "https://YOURSUBDOMAIN.ghe.com"
        }
      }
    }
  }
}
```

## Docker Command Line Usage

If you prefer to run the MCP server directly from the command line:

```bash
docker run -i --rm \
  -e GITHUB_PERSONAL_ACCESS_TOKEN="your_token_here" \
  ghcr.io/github/github-mcp-server
```

For GitHub Enterprise:

```bash
docker run -i --rm \
  -e GITHUB_PERSONAL_ACCESS_TOKEN="your_token_here" \
  -e GITHUB_HOST="https://github.your-company.com" \
  ghcr.io/github/github-mcp-server
```

## Troubleshooting

### Cannot Pull Docker Image

If you receive authentication errors when pulling the image:

```bash
docker logout ghcr.io
docker pull ghcr.io/github/github-mcp-server
```

### Connection Issues

1. **Verify Docker is running**: `docker ps`
2. **Check GitHub connectivity**: Ensure you can reach GitHub/GitHub Enterprise from your network
3. **Validate PAT**: Verify your token has the necessary permissions
4. **Check GITHUB_HOST**: Ensure the hostname is correctly formatted with `https://` prefix for Enterprise Server

### Permission Errors

If you encounter permission issues:

1. Review the scopes/permissions granted to your PAT
2. Ensure the PAT hasn't expired
3. Verify you have access to the repositories/organizations you're trying to interact with

## Features

The GitHub MCP server provides access to various GitHub APIs including:

- Repository management
- Issue and pull request operations
- Code search and navigation
- GitHub Actions workflows
- Organization and team management
- And more...

Refer to the specific MCP server documentation for the complete list of available capabilities and API endpoints.

## Additional Resources

- [GitHub Personal Access Tokens Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Docker Installation Guide](https://docs.docker.com/get-docker/)
- [VS Code Copilot Documentation](https://code.visualstudio.com/docs/copilot)
- [Model Context Protocol (MCP) Specification](https://modelcontextprotocol.io/)

## Support

For issues related to:
- **GitHub MCP Server**: Check the [github-mcp-server repository](https://github.com/github/github-mcp-server)
- **Docker**: Consult [Docker documentation](https://docs.docker.com/)
- **GitHub Copilot**: Visit [GitHub Copilot support](https://support.github.com/copilot)
