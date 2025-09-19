# AI CLI Sandbox Runner

A powerful command-line utility for running AI tools like Google's Gemini CLI or OpenAI's Codex in a secure, isolated, and sandboxed Docker environment.

This script is designed for developers who want to leverage AI assistants on their local codebase without granting them unrestricted access. It provides full project context in a read-only mode while only allowing modifications to specific, user-approved directories.

> **Developer Note**
> Hi, This project came from the need to safely integrate powerful AI tools like Codex and Gemini into complex local development workflows without compromising security or codebase integrity. I hope it helps you work smarter and safer with AI. You can find me on [LinkedIn](https://www.linkedin.com/in/hanyalsamman/).

## Demo

<video src="https://raw.githubusercontent.com/codex-corp/ai-sandbox/main/ai-tool.mp4" width="700" controls></video>

## Key Features

* **Secure by Default**: Mounts your entire project as **read-only** for context, and only selected service directories as **read-write**.
* **Secret Redaction**: Automatically backs up and redacts sensitive information like API keys from your code before the AI session begins.
* **Seamless Authentication**: Intelligently mounts host-machine credentials for the chosen tool (e.g., `~/.codex`, `~/.config/gemini-cli`) into the container, so your tools work out-of-the-box.
* **Multi-Tool Support**: Easily switch between different AI tools (e.g., `gemini`, `codex`).
* **Interactive & Non-Interactive Modes**:
    * Launch an interactive AI chat session (TUI).
    * Run non-interactive, one-shot prompts.
    * Get a direct bash shell inside the sandboxed container for debugging or manual changes (`--shell`).
* **Smart Logging**: Logs non-interactive sessions. Automatically detects interactive TUIs (like `codex` without arguments) and runs them directly for full functionality, without interfering piping.
* **Post-Session Control**: After your session, a menu lets you:
    * Review all changed files.
    * Generate a git-compatible diff file to easily apply changes in your IDE.
    * Restore your original files from the backup, discarding all changes.
* **Robust & User-Friendly**: Colored output, error handling, and a graceful session management make it a pleasure to use.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

1.  **Docker**: To run the containerized environment.
2.  **Git**: Required for the "Generate Diff" feature.
3.  **rsync**: Required for the backup and restore functionality.
4.  **AI CLI Tools**: The Docker image (`ai-sandbox` by default) must have the desired AI CLI tools (e.g., `gemini`, `codex`) installed.
5.  **gitleaks** (Optional): Required only if using the `--gitleaks` flag.

## Setup

### 1. The Script

Save the script as `ai-tool` (or `ai-tool.sh`) in the root of your project directory and make it executable:

```bash
chmod +x ai-tool
```

*(Assuming the script is named `ai-tool` and is in the current directory)*

### 2. Docker Image

Ensure your `ai-sandbox` Docker image (or the one specified by `--image`) is built and contains the necessary AI CLI tools. An example Dockerfile might look like:

```dockerfile
# Example ~/ai-sandbox/Dockerfile
FROM node:20-alpine

# Install essential tools and network utilities
RUN apk add --no-cache \
    jq curl git bash coreutils findutils sed \
    curl bind-tools net-tools

# Install AI CLIs
RUN npm install -g @google/gemini-cli @openai/codex

# Create a standard user (often 'node' in node images, but ensure it matches script expectations)
# The script uses -u $(id -u):$(id -g) and maps host paths to /home/node inside the container.
# So, ensure /home/node exists and is usable, or adjust the script's mount points/user.

RUN mkdir -p /home/node && chown -R 1000:1000 /home/node
WORKDIR /workspace
# Default user is typically 'node' (1000:1000) in node images, which aligns with script's $(id -u):$(id -g)

CMD ["/bin/bash"]
```

Build it:
```bash
cd ~/ai-sandbox
docker build -t ai-sandbox .
```

## Usage

The script is run from the root of your project. The `--services` flag is required.

### Command Structure

```bash
./ai-tool --services "<service_dirs>" [OPTIONS] [-- <TOOL_ARGS>]
```

### Options

| Flag | Description | Default |
| :--- | :--- | :--- |
| `--services "<dirs>"` | **(Required)** Space-separated list of directories to grant write access to (they will be redacted and backed up). | |
| `--tool <name>` | The AI tool to use (`gemini` or `codex`). | `gemini` |
| `--shell` | Launch an interactive bash shell instead of an AI tool. | `false` |
| `--workdir <path>` | The working directory to start in, relative to the project root. | `.` |
| `--gitleaks` | Run a `gitleaks` scan for secrets on the service directories before starting. | `false` |
| `--image <name>` | The Docker image to use for the sandbox. | `ai-sandbox` |
| `--network <name>` | The Docker network to attach the container to. Can be set via `DOCKER_NETWORK` env var. | `labeeb_appnet` (or `bridge` if env var not set) |
| `-- <args>` | All arguments after `--` are passed directly to the AI tool or shell. | |

### Examples

#### 1. Basic Interactive Session

Start an interactive chat session with the default tool (`gemini`), granting write access to the `api` and `database` directories.

```bash
./ai-tool --services "api database"
```

**What it does:**

*   Backs up and redacts secrets from the `api` and `database` directories.
*   Mounts your local AI tool credentials (e.g., `~/.config/gemini-cli`) into the container.
*   Launches the interactive TUI for the chosen tool.

#### 2. Interactive Session with Codex

Start an interactive session with `codex`, granting write access to the `frontend` directory.

```bash
./ai-tool --services "frontend" --tool codex
```

#### 3. Non-Interactive Prompt (One-Shot Command)

Ask the AI to perform a single task and print the output (and log it). This example uses `gemini`.

```bash
./ai-tool --services "worker" -- gemini -p "Can you refactor worker/main.py to be more efficient?"
```

**Note:** Non-interactive sessions are logged. Interactive TUIs (like `codex` with no args) run directly for full functionality.

#### 4. Get a Direct Shell Inside the Container

Useful for running tests, inspecting the environment, or performing manual tasks within the sandbox.

```bash
./ai-tool --services "frontend/src" --shell
```

You can also pass commands directly to the shell:

```bash
./ai-tool --services "api" --shell -- ls -la
```

#### 5. Run with Specific Docker Network

Attach the container to a specific Docker network (useful for accessing other services in a `docker-compose` setup).

```bash
./ai-tool --services "api" --network "myproject_default"
```

*(You can also set `export DOCKER_NETWORK=myproject_default` in your shell profile)*

#### 6. Using a Different Docker Image

If you have built a custom image.

```bash
./ai-tool --services "service1" --image my-custom-ai-image
```

#### 7. Running a Gitleaks Scan Before the Session

Perform a security scan for secrets before starting your AI session.

```bash
./ai-tool --services "api auth-service" --gitleaks
```

#### 8. Specifying a Working Directory

Start the session inside a specific subdirectory.

```bash
./ai-tool --services "webapp" --workdir "webapp/src/components"
```

#### 9. Combining Multiple Options

A complex example combining flags.

```bash
./ai-tool \
  --services "parser-service" \
  --tool gemini \
  --gitleaks \
  --workdir "parser-service/app" \
  -- gemini -p "Add error handling to the main function in main.go"
```

## Security Model

The script's primary goal is to provide the AI with maximum context while minimizing risk.

1.  **Read-Only Context**: The entire project directory (`$PROJECT_ROOT`) is mounted into the container as **read-only**. The AI can read any file, which is crucial for understanding dependencies and the overall architecture.
2.  **Selective Write Access**: Only the directories you specify with `--services` are layered on top as **read-write** volumes. The AI can only modify files within these folders.
3.  **Credential Isolation**: The script detects your tool choice and mounts only the necessary, pre-existing configuration directories from your host machine (e.g., `~/.codex`, `~/.config/gemini-cli`) into standard paths inside the container (`/home/node/...`). Your main host `$HOME` is not exposed.
4.  **Secret Redaction**: Before the session, a temporary backup of the specified `--services` directories is created, and secrets (API keys, etc.) are redacted from the live files used in the session. The restore function uses the clean, original backup.
5.  **Sandboxing**: Uses Docker's `--read-only` flag by default, along with `--cap-drop=ALL`, to limit the container's privileges. Writable space is provided only where strictly necessary (`/tmp`, `/var`, `/home`, and the specific service volumes).
---

## License

This project is licensed under the MIT License.
