# Multi-stage build for Symphony Elixir with Codex
FROM hexpm/elixir:1.18.2-erlang-27.2.4-ubuntu-noble-20250127 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install mise
RUN curl https://mise.run | sh
ENV PATH="/root/.local/bin:${PATH}"

# Set working directory
WORKDIR /app

# Clone Symphony
RUN git clone https://github.com/openai/symphony.git .
WORKDIR /app/elixir

# Trust mise and install
RUN mise trust && mise install

# Install deps and compile
RUN mise exec -- mix deps.get --only prod
RUN mise exec -- mix compile

# Build release
ENV MIX_ENV=prod
RUN mise exec -- mix release --overwrite

# Stage 2: Runtime with Node.js for Codex
FROM ubuntu:noble

# Install runtime dependencies including Node.js for Codex
RUN apt-get update && apt-get install -y \
    libstdc++6 \
    openssl \
    locales \
    git \
    curl \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x (required for Codex)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create non-root user
RUN groupadd -r symphony && useradd -r -g symphony symphony

# Set working directory
WORKDIR /app

# Copy release from builder
COPY --from=builder /app/elixir/_build/prod/rel/symphony ./

# Copy default WORKFLOW.md
COPY WORKFLOW.md /app/config/WORKFLOW.md

# Create directories for workspaces and logs
RUN mkdir -p /app/workspaces /app/log /app/config && chown -R symphony:symphony /app

# Switch to non-root user
USER symphony

# Install Codex CLI globally (will be authenticated at runtime)
RUN npm install -g @openai/codex

# Ensure Codex is in PATH
ENV PATH="/home/symphony/.local/bin:${PATH}"

# Expose port
EXPOSE 4000

# Default command
CMD ["./bin/symphony", "/app/config/WORKFLOW.md", "--port", "4000", "--logs-root", "/app/log"]
