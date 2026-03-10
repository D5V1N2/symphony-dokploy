# Symphony on Dokploy

OpenAI Symphony - Autonomous coding agent orchestrator running in a Dokploy container.

## What is Symphony?

Symphony polls Linear for issues and spawns Codex agents to work on them automatically. It creates isolated workspaces per issue and manages the entire agent lifecycle.

**Features:**
- Monitors Linear projects for new work
- Creates isolated workspace per issue  
- Spawns Codex agents to implement changes
- Phoenix LiveView dashboard for observability
- Automatic cleanup when issues are closed

## Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│  Linear API     │◄────┤   Symphony   │────►│   Codex     │
│  (Issue Tracker)│     │  (Elixir/OTP)│     │   Agents    │
└─────────────────┘     └──────────────┘     └─────────────┘
                               │
                               ▼
                        ┌──────────────┐
                        │  Dashboard   │
                        │  (Port 4000) │
                        └──────────────┘
```

## Setup Instructions

### 1. Prerequisites

You need:
- Linear account with API access
- Linear project with issues to work on
- OpenAI API key (for Codex)
- Dokploy instance running

### 2. Get Linear API Key

1. Go to Linear → Settings → Security & access → Personal API keys
2. Create a new key
3. Save it securely - you'll need it for the env vars

### 3. Get Linear Project Slug

1. In Linear, right-click your project
2. Copy URL (looks like: `https://linear.app/yourteam/project/project-slug-123`)
3. The slug is `project-slug-123`

### 4. Configure Environment Variables

In Dokploy, set these environment variables for the Symphony compose app:

```bash
LINEAR_API_KEY=lin_api_your_key_here
LINEAR_PROJECT_SLUG=your-project-slug
OPENAI_API_KEY=sk-your-openai-key
```

### 5. Configure WORKFLOW.md

Edit `WORKFLOW.md` in this directory to customize:
- Project slug
- Active/terminal states
- Hooks (clone your repo, etc.)
- Codex behavior settings

### 6. Build and Deploy

The compose file uses local build context. Deploy via Dokploy:

```bash
# From this directory
dokploy-compose deploy
```

Or manually trigger deploy in Dokploy UI.

### 7. Authenticate Codex (One-time)

After first deploy, you need to authenticate Codex in the container:

```bash
# SSH into the Dokploy host, then:
docker exec -it symphony bash

# Login to Codex
codex login
# Follow prompts to authenticate with OpenAI

# Or set API key directly
export OPENAI_API_KEY=sk-your-key
codex config set api_key $OPENAI_API_KEY
```

### 8. Access Dashboard

Once running, access the Symphony dashboard at:
- Via Tailscale: `https://symphony.tail34364b.ts.net`
- Direct: `http://100.126.18.86:port` (check assigned port)

Dashboard endpoints:
- `/` - LiveView dashboard
- `/api/v1/state` - JSON API for current state
- `/api/v1/refresh` - Trigger manual refresh

## Customizing for Your Repo

The key part is the `hooks.after_create` in WORKFLOW.md. This runs when a new workspace is created:

```yaml
hooks:
  after_create: |
    git clone git@github.com:your-org/your-repo.git .
    # Any other setup (install deps, etc.)
```

If you need SSH keys for private repos, mount them as secrets:

```yaml
# In docker-compose.yml
secrets:
  ssh_key:
    file: ~/.ssh/id_rsa

services:
  symphony:
    secrets:
      - ssh_key
    # ...
```

## Custom Linear States

Symphony expects certain states by default. If your team uses different workflow states, update WORKFLOW.md:

```yaml
tracker:
  active_states:
    - "Backlog"
    - "In Progress"
    - "In Review"
  terminal_states:
    - "Done"
    - "Closed"
```

## Monitoring

### View Logs
```bash
docker logs -f symphony
```

### View Agent Workspaces
```bash
docker exec -it symphony ls -la /app/workspaces
```

### Check Symphony Status
```bash
curl http://symphony.tail34364b.ts.net/api/v1/state
```

## Troubleshooting

### "LINEAR_API_KEY not set"
- Check environment variables in Dokploy
- Verify the variable is set in the compose app, not just the project

### "Codex not found"
- Codex CLI is installed globally in the container
- Check: `docker exec -it symphony which codex`

### "Authentication required"
- Codex needs OpenAI authentication
- Run `codex login` inside the container

### Workspaces not persisting
- Check volume mounts in compose file
- Verify `symphony-workspaces` volume exists: `docker volume ls`

## Files

- `Dockerfile` - Production image with Elixir + Node.js + Codex
- `docker-compose.yml` - Compose configuration for Dokploy
- `WORKFLOW.md` - Symphony workflow configuration (see SPEC.md for details)
- `README.md` - This file

## Resources

- [Symphony GitHub](https://github.com/openai/symphony)
- [Symphony SPEC.md](https://github.com/openai/symphony/blob/main/SPEC.md)
- [Codex App Server Docs](https://developers.openai.com/codex/app-server/)
- [Harness Engineering](https://openai.com/index/harness-engineering/)

## Security Notes

- Symphony is prototype software - use in trusted environments only
- Keep LINEAR_API_KEY and OPENAI_API_KEY secret
- Consider using Dokploy secrets management for API keys
- Review WORKFLOW.md approval_policy settings carefully
