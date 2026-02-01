---
name: openclaw-claude-usage
description: Report Claude usage for Max/Pro subscriptions, agent vibe coding, and API costs. Use when asked about Claude usage, limits, costs, or utilization.
---

# Claude Usage Reporting

Report on Claude usage across three sources:
1. **Claude Max/Pro Plan** — subscription limits (% of weekly quota)
2. **Agent Vibe Coding** — the OpenClaw agent's own Claude Code sessions
3. **API Usage** — direct API costs from applications (if configured)

## Report Format

Use ASCII bar charts for all sections:

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

## 1. Claude Max Plan Usage

The `/usage` command shows global subscription limits. Run Claude Code interactively:

```javascript
// Start claude with PTY
exec({ command: "claude", pty: true, yieldMs: 5000 })

// Send /usage command
process({ action: "send-keys", sessionId: "...", literal: "/usage" })
process({ action: "send-keys", sessionId: "...", keys: ["Enter"] })

// Poll for output - look for:
// "Current session: X% used"
// "Current week (all models): X% used"  
// "Current week (Sonnet only): X% used"

// Exit cleanly
process({ action: "send-keys", sessionId: "...", literal: "/exit" })
process({ action: "send-keys", sessionId: "...", keys: ["Enter"] })
```

**⚠️ Important:** Do NOT create custom commands in `~/.claude/commands/usage.md` — this shadows the native `/usage` command.

## 2. Agent Vibe Coding (ccusage)

Track the OpenClaw agent's own Claude Code sessions using `ccusage`:

```bash
# Daily usage
ccusage daily --since YYYYMMDD

# Weekly breakdown
ccusage weekly

# Monthly breakdown  
ccusage monthly
```

This shows token usage and theoretical costs for the agent's vibe coding work (building features, debugging, etc.). Note: This is container-local data, not global account usage.

## 3. API Usage (Optional)

If `CLAUDE_ADMIN_KEY` is set, query API billing costs:

```bash
curl "https://api.anthropic.com/v1/organizations/cost_report?starting_at=YYYY-MM-DD" \
  --header "anthropic-version: 2023-06-01" \
  --header "x-api-key: $CLAUDE_ADMIN_KEY"
```

Or use the included script:
```bash
./scripts/usage-report.sh [DAYS]
```

**Note:** API may return inflated values. Divide by 100 if costs seem too high.

## Prerequisites

1. **Claude Code CLI:** `npm install -g @anthropic-ai/claude-code`
2. **Authenticated:** `~/.claude/.credentials.json` exists
3. **ccusage:** `npm install -g ccusage`
4. **(Optional)** `CLAUDE_ADMIN_KEY` env var for API costs

## Cron Setup

For automated daily/weekly/monthly reports:

```json
{
  "name": "Claude Usage - Daily",
  "schedule": {"kind": "cron", "expr": "0 16 * * *", "tz": "UTC"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate Claude usage report with all three sections (Max Plan, Agent Vibe Coding, API) and post to the appropriate channel.",
    "deliver": true
  }
}
```

## Example Prompts

- "How much Claude have I used?"
- "Show my Claude Max usage"
- "What are my weekly limits?"
- "Check my API costs for January"
- "Generate a usage report"
