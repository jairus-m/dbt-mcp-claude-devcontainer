# dbt + MCP + Claude Code CLI Dev Container Template
A development container template for local dbt setup (either Cloud CLI or Fusion ) that connects and configures the dbt MCP server and Claude Code CLI.

## What's a dev container?
- A dev container is a Docker container specifically configured to serve as a fully featured, consistent, isolated, and portable development environment
- Defined in `.devcontainer/devcontainer.json` within a project
- Read more about them:
  - [VS Code Docs](https://code.visualstudio.com/docs/devcontainers/containers)
  - [GitHub Docs](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers)

#### General benefits of using containers include:
- Isolated environments for each project (preventing dependency and path conflicts)
- Reproducible builds and consistent environments across teams that are easily distributed
- Faster setup and onboarding for new contributors
- Simplified /development without impacting your main system configuration or other projects

## Requirements
- [Docker Desktop](https://docs.docker.com/desktop/)
- [VS Code](https://code.visualstudio.com/download) with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) (or [Remote Explorer](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-explorer)) extension
- A `dbt` project with a proper:
  - `dbt_project.yml` in the workspace/project folder root
  - Proper configs in your local `~/.dbt` directory
- A developer [PAT](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens) from dbt Cloud 
- [Anthropic API Credentials](https://docs.anthropic.com/en/docs/get-started)

## Features
This dev container will automatically:
- Install the [dbt Cloud CLI](https://docs.getdbt.com/docs/cloud/cloud-cli-installation) or [dbt Fusion](https://github.com/dbt-labs/dbt-fusion) depending on your selected base image
- Configure the [dbt MCP server](https://github.com/dbt-labs/dbt-mcp)
- Install and configures [Claude Code CLI](https://docs.anthropic.com/en/docs/get-started#install-the-sdk)
- Install the [dbt Power User](https://marketplace.visualstudio.com/items?itemName=innoverio.vscode-dbt-power-user) extension or [official dbt VS Code Extension](https://marketplace.visualstudio.com/items?itemName=dbtLabsInc.dbt) depending on your selected base image
- Installs [pre-commits](https://github.com/pre-commit/pre-commit)
- Installs [uv](https://docs.astral.sh/uv/getting-started/features/)

Note: All tools and LLM’s are installed and scoped to the ephemeral dev container itself and are completely isolated from your machine.

## Usage

1. Add the following to your project's `.devcontainer/devcontainer.json` file:
   - For Fusion: [dbt Fusion dev container JSON config](https://github.com/jairus-m/dbt-mcp-claude-devcontainer/blob/main/src/dbt-fusion/.devcontainer/devcontainer.json)
   - For Cloud CLI: [dbt Cloud CLI dev container JSON config](https://github.com/jairus-m/dbt-mcp-claude-devcontainer/blob/main/src/dbt-cloud-cli/.devcontainer/devcontainer.json)

2. Add the following to your project's `.devcontainer/devcontainer.env` file:
   - [Dev Container Environment Variables Needed for dbt MCP and Claude Code CLI](https://github.com/jairus-m/dbt-mcp-claude-devcontainer/blob/main/src/devcontainer-template.env)
   - Note:
     - Refer to [dbt-mcp/README.md](https://github.com/dbt-labs/dbt-mcp/blob/main/README.md) for environment variable configuration
     - Your Anthropic credentials enironment variables will depend on if you're using the defualt Anthropic base URL or a 3rd Party Proxy

4. Confirm that you have the following in your projects root:
    ```bash
    .devcontainer
    ├── devcontainer.env  # Env vars
    └── devcontainer.json # Dev container config
    ```

5. Open your project in VS Code and use the Dev Containers (or Remote Explorer) extension to build and run the container. ([docs](https://code.visualstudio.com/docs/devcontainers/containers))

6. Allow some time for the extensions to install
  - If using Fusion, follow dbt's prompt for further installation of the executable

## Verify Installation
```bash
# Verify dbt
dbt --version
dbt debug

# Verify claude 
claude --version

# Verify dbt-mcp
claude
/mcp

# Verify pre-commit
pre-commit --version

# Verify uv
uv --version
```
