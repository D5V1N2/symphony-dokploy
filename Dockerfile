# Symphony - Self-Contained Container with All Dependencies
# Installs: Elixir/OTP, Node.js, Codex CLI, Git

FROM hexpm/elixir:1.18.2-erlang-27.2.4-ubuntu-noble-20250127

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    ca-certificates \
    gnupg \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x (required for Codex CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install mise for Elixir version management
RUN curl https://mise.run | sh
ENV PATH="/root/.local/bin:${PATH}"

# Set working directory for Symphony
WORKDIR /app

# Clone Symphony repository
RUN git clone https://github.com/openai/symphony.git .

# Navigate to elixir directory and build
WORKDIR /app/elixir

# Trust mise and install Elixir/Erlang versions specified in .mise.toml
RUN mise trust && mise install

# Install Elixir dependencies
RUN mise exec -- mix deps.get --only prod

# Compile the application
ENV MIX_ENV=prod
RUN mise exec -- mix compile

# Build the release
RUN mise exec -- mix release --overwrite

# Install Codex CLI globally
RUN npm install -g @openai/codex

# Create directories for config, workspaces, and logs
RUN mkdir -p /app/config /app/workspaces /app/log

# Copy default WORKFLOW.md (will be overridden by volume mount if provided)
COPY WORKFLOW.md /app/config/WORKFLOW.md

# Set environment variables
ENV SYMPHONY_WORKSPACE_ROOT=/app/workspaces
ENV PATH="/root/.local/bin:/app/elixir/bin:${PATH}"

# Expose port for Phoenix dashboard
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:4000/api/v1/state || exit 1

# Default command
CMD ["mise", "exec", "--", "/app/elixir/_build/prod/rel/symphony/bin/symphony", "/app/config/WORKFLOW.md", "--port", "4000", "--logs-root", "/app/log"]
