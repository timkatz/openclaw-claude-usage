# Claude Usage Reporting for OpenClaw

Track and report Claude usage from within OpenClaw, covering both **subscription plans** (Max/Pro) and **API usage**.

## Overview

Anthropic has **two separate billing systems**:

| System | Billing | What It Tracks |
|--------|---------|----------------|
| **Claude Max/Pro** | $20-200/month flat | All Claude usage across your account |
| **Claude API** | Pay-per-token | Direct API calls from your applications |

This skill enables OpenClaw to report on both.

---

## Part 1: Subscription Usage (Claude Max/Pro)

This tracks your **entire Claude account usage** — web, mobile, desktop, and all Claude Code sessions.

### Setup

#### Step 1: Install Claude Code CLI in Container

```bash
# Get your container name
docker ps | grep openclaw

# Install Claude Code CLI
docker exec <container-name> npm install -g @anthropic-ai/claude-code

# Install ccusage (optional - for OpenClaw's own session history)
docker exec <container-name> npm install -g ccusage
```

#### Step 2: Authenticate Claude Code

Claude Code requires OAuth authentication with your Claude account.

**Option A: Interactive Auth (recommended)**
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

#### Step 3: Make Auth Persistent

Auth files are lost when the container restarts. To persist them:

**Option A: Volume Mount (recommended)**

Add to your docker-compose.yml:
```yaml
volumes:
  - /path/on/host/.claude:/home/node/.claude
```

**Option B: Re-copy After Restart**

Re-run the docker cp command after each restart.

### Getting Account Usage

The `/usage` command in Claude Code shows your **global account usage** across all devices and sessions.

**Important:** `/usage` only works interactively — it cannot be called via `claude -p "..."`.

#### Interactive Method (for testing)

```bash
docker exec -it <container-name> claude
# Then type: /usage
# You'll see:
#   Current session: X% used
#   Current week (all models): X% used
#   Current week (Sonnet only): X% used
```

#### Automated Method (for OpenClaw cron jobs)

OpenClaw can run Claude Code interactively using PTY mode:

```javascript
// Start claude with PTY
exec({ command: "claude", pty: true, yieldMs: 5000 })

// Send /usage command
process({ action: "send-keys", sessionId: "...", literal: "/usage" })
process({ action: "send-keys", sessionId: "...", keys: ["Enter"] })

// Poll for output
process({ action: "poll", sessionId: "..." })

// Parse the percentages from output
// Exit cleanly
process({ action: "send-keys", sessionId: "...", literal: "/exit" })
```

### What About ccusage?

`ccusage` reads local JSONL session files from `~/.claude/projects/`. This only shows usage from **Claude Code sessions initiated from that specific machine/container**.

- If OpenClaw uses Claude Code for its own "vibe coding" tasks, ccusage will show that usage
- It does **NOT** show your global account usage (web, mobile, other devices)
- For global account usage, use the `/usage` command as described above

---

## Part 2: API Usage (Optional)

If you also use the Anthropic API directly (for your own applications, integrations, etc.), you can include that in your reports.

### Setup

1. Get an **Admin API Key** from https://console.anthropic.com → Settings → Admin API Keys
2. Add to your OpenClaw environment:
```bash
CLAUDE_ADMIN_KEY=sk-ant-admin-...
```

### Getting API Costs

```bash
curl "https://api.anthropic.com/v1/organizations/cost_report?starting_at=YYYY-MM-DD" \
  --header "anthropic-version: 2023-06-01" \
  --header "x-api-key: $CLAUDE_ADMIN_KEY"
```

Or use the bundled script:
```bash
./scripts/usage-report.sh [days]
```

### Known Issue: 100x Bug

The Admin API may return values ~100x higher than the Console shows. If your numbers seem inflated, divide by 100. The Console is authoritative.

---

## Setting Up Automated Reporting

### OpenClaw Cron Job for Daily Reports

Add a cron job that:
1. Runs Claude Code interactively to get `/usage`
2. Optionally pulls API costs
3. Posts a formatted report to your preferred channel

Example cron job payload:
```json
{
  "name": "Claude Usage - Daily",
  "schedule": {"kind": "cron", "expr": "0 16 * * *", "tz": "UTC"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate Claude usage report.\n\n1. Run 'claude' with PTY, send '/usage', capture output for account limits\n2. If CLAUDE_ADMIN_KEY is set, hit Admin API for API costs\n3. Format report with ASCII charts\n4. Post to channel\n\nReport format:\n📊 Claude Usage Report\n\n**Account Limits:**\n• Session: X% used\n• Week (all models): X% used\n\n**API Costs (if applicable):**\n[date] : ████████░░ $X.XX",
    "deliver": true,
    "channel": "discord"
  }
}
```

---

## Report Format

Use ASCII bar charts (more readable than tables):

```
📊 Claude Usage Report — 2026-02-01

**Account Limits (Claude Max):**
• Session: 11% used (resets in 6h)
• Week (all models): 30% used (resets Feb 6)
• Week (Sonnet only): 1% used (resets Feb 7)

**API Costs:** (if applicable)
2026-01-31 : ██░░░░░░░░░░░░░░░░░░ $0.03
2026-02-01 : █░░░░░░░░░░░░░░░░░░░ $0.02
```

---

## Quick Reference

```bash
# Check if Claude Code is installed
claude --version

# Check auth status
ls -la ~/.claude/.credentials.json

# Get global account usage (interactive)
claude
# then type: /usage

# Get API costs (if using API)
curl -s "https://api.anthropic.com/v1/organizations/cost_report?starting_at=2026-01-01" \
  -H "anthropic-version: 2023-06-01" \
  -H "x-api-key: $CLAUDE_ADMIN_KEY"

# Get OpenClaw's own Claude Code session history
ccusage daily --since 20260101
```

---

## File Locations

| File | Purpose |
|------|---------|
| `~/.claude/.credentials.json` | OAuth tokens for Claude Code |
| `~/.claude/projects/` | Local session JSONL files (OpenClaw's own sessions) |
| `CLAUDE_ADMIN_KEY` env var | Admin API access (for API cost reporting) |

---

## License

MIT

---

Built for [OpenClaw](https://github.com/anthropics/openclaw) 🤖
