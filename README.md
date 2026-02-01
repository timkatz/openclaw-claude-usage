# Claude Usage Reporting for OpenClaw

Track and report Claude usage from within OpenClaw, covering both **subscription plans** (Max/Pro) and **API usage**.

## Overview

Anthropic has **two separate billing systems**:

| System | Billing | What You See |
|--------|---------|--------------|
| **Claude Max/Pro** | $20-200/month flat | % of weekly limit used |
| **Claude API** | Pay-per-token | $ cost per day |

This skill enables OpenClaw to report on both.

---

## Setup for OpenClaw (Docker)

### Step 1: Install Claude Code CLI in Container

```bash
# Get your container name
docker ps | grep openclaw

# Install Claude Code CLI
docker exec <container-name> npm install -g @anthropic-ai/claude-code

# Install ccusage for historical data
docker exec <container-name> npm install -g ccusage
```

### Step 2: Authenticate Claude Code

Claude Code requires OAuth authentication with your Claude account.

**Option A: Interactive Auth (one-time)**
```bash
# Start interactive session in container
docker exec -it <container-name> claude

# Complete the OAuth flow:
# 1. Select "Claude account with subscription"
# 2. Open the URL it provides in your browser
# 3. Sign in and copy the code
# 4. Paste the code back into the terminal
# 5. Exit with /exit
```

**Option B: Copy Auth from Host**

If you've already authenticated Claude Code on your host machine:
```bash
# Copy auth files into container
docker cp ~/.claude <container-name>:/home/node/.claude
```

### Step 3: Make Auth Persistent (Recommended)

By default, auth files are lost when the container restarts. To persist them:

**Option A: Volume Mount (recommended)**

Add to your docker-compose.yml or docker run command:
```yaml
volumes:
  - /path/on/host/.claude:/home/node/.claude
```

**Option B: Re-copy After Restart**

Create a startup script that copies auth files:
```bash
docker cp /path/to/.claude <container-name>:/home/node/.claude
```

### Step 4: Set Up Admin API Key (for API costs)

Get an Admin API key from https://console.anthropic.com → Settings → Admin API Keys

Add to your OpenClaw environment:
```bash
CLAUDE_ADMIN_KEY=sk-ant-admin-...
```

---

## Using the Skill

Once set up, OpenClaw can report usage via cron jobs or on-demand.

### Subscription Usage (Claude Max/Pro)

The `/usage` command shows current limits but **only works interactively**. For automated reporting, use `ccusage`:

```bash
# Daily usage (run inside container)
ccusage daily --since 20260101

# Weekly summary
ccusage weekly

# Monthly summary  
ccusage monthly
```

This reads local JSONL files from `~/.claude/projects/` and calculates token usage + theoretical costs.

### API Usage (Hux, production apps, etc.)

Use the Admin API:

```bash
curl "https://api.anthropic.com/v1/organizations/cost_report?starting_at=YYYY-MM-DD" \
  --header "anthropic-version: 2023-06-01" \
  --header "x-api-key: $CLAUDE_ADMIN_KEY"
```

Or use the bundled script:
```bash
./scripts/usage-report.sh [days]
```

---

## OpenClaw Cron Job Examples

### Daily Usage Report

```json
{
  "name": "Claude Usage - Daily",
  "schedule": {"kind": "cron", "expr": "0 16 * * *", "tz": "UTC"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate Claude usage report. Run ccusage daily for subscription usage, hit Admin API for API costs. Post to #briefs with ASCII charts.",
    "deliver": true,
    "channel": "discord"
  }
}
```

### Getting Current Limits (Interactive)

Since `/usage` requires interaction, you can run Claude Code with PTY:

```javascript
// In OpenClaw, use exec with pty:true
exec({ command: "claude", pty: true })
// Then send-keys: "/usage", "Enter", etc.
```

---

## Report Format

Use ASCII bar charts (more readable than tables in Discord/chat):

```
📊 Claude Usage Report — 2026-02-01

**Claude Max Subscription:**
2026-02-01 : ██░░░░░░░░░░░░░░░░░░ $0.13
             47,262 tokens (Opus + Sonnet)

**API Usage:**
2026-01-31 : █░░░░░░░░░░░░░░░░░░░ $0.03

**Current Limits:**
• Session: 11% used
• Week (all models): 30% used
```

---

## Known Issues

### Admin API 100x Bug
The Admin API returns values ~100x higher than the Console shows. Divide by 100 when values seem inflated. The Console is authoritative.

### /usage Not Automatable
The `/usage` slash command only works interactively inside Claude Code. For automated reporting:
- Use `ccusage` for historical token data
- Or build a PTY wrapper to interact with Claude Code

### Auth Persistence
Container restarts lose auth files unless you volume-mount `~/.claude/`.

---

## File Locations

| File | Purpose |
|------|---------|
| `~/.claude/.credentials.json` | OAuth tokens |
| `~/.claude/projects/` | Session JSONL files |
| `CLAUDE_ADMIN_KEY` env var | Admin API access |

---

## Quick Reference

```bash
# Check if Claude Code is working
claude --version

# Check auth status
ls -la ~/.claude/.credentials.json

# Get subscription usage (historical)
ccusage daily --since 20260101

# Get API costs
curl -s "https://api.anthropic.com/v1/organizations/cost_report?starting_at=2026-01-01" \
  -H "anthropic-version: 2023-06-01" \
  -H "x-api-key: $CLAUDE_ADMIN_KEY"

# Interactive usage check
claude
# then type: /usage
```

---

## License

MIT

---

Built by [Kai](https://github.com/dyodeinc) for OpenClaw 🤖
