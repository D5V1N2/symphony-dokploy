---
tracker:
  kind: linear
  # Replace with your Linear project slug
  # Get it from: right-click project in Linear → Copy URL → extract slug
  project_slug: "${LINEAR_PROJECT_SLUG:-your-project-slug}"
  # API key from environment
  api_key: "$LINEAR_API_KEY"
  # States that Symphony will pick up issues from
  active_states:
    - "Todo"
    - "In Progress"
  # States that mean the issue is done
  terminal_states:
    - "Done"
    - "Closed"
    - "Cancelled"
    - "Canceled"
    - "Duplicate"

polling:
  interval_ms: 30000

workspace:
  root: /app/workspaces

hooks:
  after_create: |
    # Clone your repo here
    # Example: git clone git@github.com:your-org/your-repo.git .
    echo "Workspace created for issue"
  
  before_run: |
    echo "Starting work on issue"
  
  after_run: |
    echo "Finished work on issue"
  
  before_remove: |
    echo "Cleaning up workspace"
  
  timeout_ms: 60000

agent:
  max_concurrent_agents: 5
  max_turns: 20
  max_retry_backoff_ms: 300000

codex:
  # Command to launch Codex in app-server mode
  command: codex app-server
  
  # Approval policy - these are safer defaults
  # Options: untrusted, on-failure, on-request, never
  # Or object form: {"reject": {"sandbox_approval": true, "rules": true}}
  approval_policy: on-request
  
  # Sandbox mode
  # Options: read-only, workspace-write, danger-full-access
  thread_sandbox: workspace-write
  
  # Turn timeout (1 hour)
  turn_timeout_ms: 3600000
  
  # Read timeout for Codex responses
  read_timeout_ms: 5000
  
  # Stall detection timeout (5 minutes)
  stall_timeout_ms: 300000

server:
  port: 4000
---

You are an autonomous coding agent working on a Linear issue.

**Issue:** {{ issue.identifier }}
**Title:** {{ issue.title }}

**Description:**
{{ issue.description }}

Your task is to:
1. Understand the issue requirements
2. Explore the codebase to understand the context
3. Implement the necessary changes
4. Test your changes if tests exist
5. Commit your work with a descriptive message

**Guidelines:**
- Work only within the workspace directory
- Make focused, minimal changes to address the issue
- Follow existing code patterns and style
- Write clear commit messages
- If you get stuck or need clarification, leave a comment on the Linear issue

{% if attempt %}
**Note:** This is a retry/continuation attempt (#{{ attempt }}).
{% endif %>

Get to work!
