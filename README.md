# OpenClaw Claude Usage Skill

An OpenClaw skill for reporting Claude usage — both **subscription plans** (Max/Pro) and **API usage**.

Ask your agent things like:
- "How much Claude have I used this week?"
- "Show my Claude Max usage"
- "What are my API costs for January?"

## Quick Start

### 1. Install the Skill

Copy `SKILL.md` to your OpenClaw skills directory, or point your agent to this repo.

### 2. Set Up Claude Code (for subscription usage)

```bash
# Install Claude Code CLI in your container
docker exec <container-name> npm install -g @anthropic-ai/claude-code

# Authenticate (interactive)
docker exec -it <container-name> claude
# Follow OAuth flow, then /exit
```

### 3. (Optional) Set Up Admin API Key (for API costs)

If you also use the Anthropic API directly:
```bash
CLAUDE_ADMIN_KEY=sk-ant-admin-...
```

That's it! Your agent can now report on Claude usage.

---

## What This Skill Reports

### Subscription Usage (Claude Max/Pro)

Shows your **global account usage** across all devices — web, mobile, desktop, all Claude Code sessions everywhere.

```
**Account Limits (Claude Max):**
• Session: 11% used (resets in 6h)
• Week (all models): 30% used (resets Feb 6)
• Week (Sonnet only): 1% used (resets Feb 7)
```

### API Usage (Optional)

If you use the Anthropic API for your own applications:

```
**API Costs:**
2026-01-30 : ██░░░░░░░░░░░░░░░░░░ $0.03
2026-01-31 : ██░░░░░░░░░░░░░░░░░░ $0.03
Monthly total: $0.89
```

---

## Understanding the Two Systems

Anthropic has **two completely separate billing systems**:

| System | Billing | What It Tracks | How to Check |
|--------|---------|----------------|--------------|
| **Claude Max/Pro** | $20-200/month flat | All Claude usage (web, mobile, desktop) | `/usage` in Claude Code |
| **Claude API** | Pay-per-token | Direct API calls from your apps | Admin API |

**Important:** These systems don't share data. Subscription usage is tracked as % of limits, API usage is tracked as $ costs.

---

## Detailed Setup

### Installing Claude Code in Docker

```bash
# Find your OpenClaw container
docker ps | grep openclaw

# Install Claude Code
docker exec <container-name> npm install -g @anthropic-ai/claude-code

# (Optional) Install ccusage for container session history
docker exec <container-name> npm install -g ccusage
```

### Authenticating Claude Code

**Option A: Interactive OAuth (recommended)**
```bash
docker exec -it <container-name> claude

# 1. Select "Claude account with subscription"
# 2. Open the URL in your browser
# 3. Sign in and copy the code
# 4. Paste the code
# 5. Type /exit
```

**Option B: Copy from Host**
```bash
# If already authenticated on host machine
docker cp ~/.claude <container-name>:/home/node/.claude
```

### Making Auth Persistent

Auth files are lost on container restart. To persist:

**Volume Mount (recommended):**
```yaml
# docker-compose.yml
volumes:
  - ./claude-auth:/home/node/.claude
```

**Or re-copy after restart.**

### Admin API Key (for API costs)

1. Go to https://console.anthropic.com → Settings → Admin API Keys
2. Create a new key
3. Add to your environment: `CLAUDE_ADMIN_KEY=sk-ant-admin-...`

---

## How the Skill Works

### Getting Subscription Usage

The `/usage` command in Claude Code shows global account limits, but it **only works interactively**. The skill runs Claude Code with PTY:

```javascript
// Start claude with PTY
exec({ command: "claude", pty: true })

// Send /usage command
process({ action: "send-keys", literal: "/usage" })
process({ action: "send-keys", keys: ["Enter"] })

// Parse output for percentages
// Exit cleanly with /exit
```

### Getting API Costs

```bash
curl "https://api.anthropic.com/v1/organizations/cost_report?starting_at=YYYY-MM-DD" \
  --header "anthropic-version: 2023-06-01" \
  --header "x-api-key: $CLAUDE_ADMIN_KEY"
```

### What About ccusage?

`ccusage` reads local session files from `~/.claude/projects/`. This only shows sessions **from that specific container** — useful if your OpenClaw agent does its own Claude Code work ("vibe coding").

For global account usage, the skill uses `/usage`.

---

## Setting Up Automated Reporting (Optional)

Want daily/weekly reports? Set up a cron job:

### Daily Report Example

```json
{
  "name": "Claude Usage - Daily",
  "schedule": {"kind": "cron", "expr": "0 16 * * *", "tz": "UTC"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate Claude usage report and post to #briefs channel.",
    "deliver": true,
    "channel": "discord"
  }
}
```

### Weekly Report Example

```json
{
  "name": "Claude Usage - Weekly",
  "schedule": {"kind": "cron", "expr": "0 16 * * 1", "tz": "UTC"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn", 
    "message": "Generate weekly Claude usage report with trends.",
    "deliver": true,
    "channel": "discord"
  }
}
```

---

## Report Format

The skill uses ASCII bar charts (readable in Discord/Slack/chat):

```
📊 Claude Usage Report — 2026-02-01

**Account Limits (Claude Max):**
• Session: 11% used (resets in 6h)
• Week (all models): 30% used (resets Feb 6)
• Week (Sonnet only): 1% used (resets Feb 7)

**API Costs:** (if configured)
2026-01-30 : ██░░░░░░░░░░░░░░░░░░ $0.03
2026-01-31 : ██░░░░░░░░░░░░░░░░░░ $0.03

**This Week Total:** $0.06
```

---

## Known Issues

### Admin API 100x Bug
The Admin API may return values ~100x higher than Console shows. Divide by 100 if values seem inflated.

### /usage is Interactive Only
Cannot be called via `claude -p "..."`. Must use PTY interaction.

### Auth Persistence
Container restarts lose auth unless volume-mounted.

---

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill instructions for OpenClaw |
| `scripts/usage-report.sh` | Standalone script for API costs |
| `~/.claude/.credentials.json` | OAuth tokens (in container) |

---

## License

MIT

---

Built for [OpenClaw](https://openclaw.ai) 🤖
