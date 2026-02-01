# OpenClaw Claude Usage Skill

An OpenClaw skill for reporting Claude usage across **three sources**:
1. **Claude Max/Pro Plan** — subscription limits (% of weekly quota)
2. **Agent Vibe Coding** — the OpenClaw agent's own Claude Code sessions
3. **API Usage** — direct API costs from applications (optional)

## Report Format

```
📊 Claude Usage Report — [date]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Claude Max Plan Usage**
Session      : ████████░░░░░░░░░░░░ 40%
Week (all)   : ██████░░░░░░░░░░░░░░ 32%
Week (Sonnet): █░░░░░░░░░░░░░░░░░░░ 1%

**Agent Vibe Coding**
[date] : ████░░░░░░░░░░░░░░░░ 47K tokens ($0.15)

**API Usage**
[date] : ██░░░░░░░░░░░░░░░░░░ $0.03

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Summary**
• Max Plan: 32% of weekly limit
• Agent Coding: $0.15 theoretical
• API: $0.03
```

## Quick Start

### 1. Install the Skill

Copy `SKILL.md` to your OpenClaw skills directory, or point your agent to this repo.

### 2. Set Up Claude Code

```bash
# Install in container
docker exec <container> npm install -g @anthropic-ai/claude-code
docker exec <container> npm install -g ccusage

# Authenticate (interactive)
docker exec -it <container> claude
# Follow OAuth flow, then /exit
```

### 3. (Optional) API Key for Direct API Costs

```bash
CLAUDE_ADMIN_KEY=sk-ant-admin-...
```

## The Three Usage Sources

### 1. Claude Max Plan Usage

**What:** Global account limits — all Claude usage (web, mobile, desktop, all devices)

**How:** Run `/usage` in Claude Code CLI

**Shows:**
- Session % (resets daily at 8am UTC)
- Week (all models) % 
- Week (Sonnet only) %

### 2. Agent Vibe Coding

**What:** The OpenClaw agent's own Claude Code sessions — when the agent uses Claude Code to build features, debug, refactor, etc.

**How:** `ccusage daily/weekly/monthly`

**Shows:**
- Token usage per day/week
- Theoretical cost (what it would cost on pay-per-token)

**Note:** This is container-local data only.

### 3. API Usage (Optional)

**What:** Direct API costs from your applications

**How:** Admin API with `CLAUDE_ADMIN_KEY`

**Shows:**
- Daily $ costs
- Monthly totals

## Automated Reporting

Set up cron jobs for daily/weekly/monthly reports:

```json
{
  "name": "Claude Usage - Daily",
  "schedule": {"kind": "cron", "expr": "0 16 * * *", "tz": "UTC"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate Claude usage report with all three sections and post to the appropriate channel.",
    "deliver": true
  }
}
```

## Important Notes

### Don't Shadow /usage

Do NOT create custom commands in `~/.claude/commands/usage.md` — this overrides the native `/usage` command that shows subscription limits.

### Auth Persistence

Claude Code auth is lost on container restart. Either:
- Volume mount `~/.claude/` 
- Re-authenticate after restart

### API Values

The Admin API may return inflated values. Divide by 100 if costs seem too high.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill instructions for OpenClaw agents |
| `scripts/usage-report.sh` | Standalone script for API costs |

## License

MIT

Built for [OpenClaw](https://openclaw.ai) 🤖
