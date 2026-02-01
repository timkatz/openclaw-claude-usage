---
name: openclaw-claude-usage
description: Report Claude usage for Max/Pro subscriptions and API costs. Use when asked about Claude usage, limits, costs, or utilization. Can show global account usage (% of weekly limits) and optionally API costs ($ spent).
---

# Claude Usage Reporting

Report on Claude usage across both subscription and API billing.

## What You Can Report

### 1. Subscription Usage (Claude Max/Pro)
Shows **global account limits** — usage across all devices, web, mobile, desktop.

### 2. API Usage (if configured)
Shows **dollar costs** for direct API calls from applications.

## Getting Subscription Usage

The `/usage` command shows global limits but only works interactively. Run Claude Code with PTY:

```javascript
// Start claude interactively
exec({ command: "claude", pty: true, yieldMs: 5000 })

// Wait for startup, then send /usage
process({ action: "send-keys", sessionId: "...", literal: "/usage" })
process({ action: "send-keys", sessionId: "...", keys: ["Enter"] })

// Poll for output (look for "% used")
process({ action: "poll", sessionId: "..." })

// Parse these lines:
// "Current session: X% used"
// "Current week (all models): X% used"  
// "Current week (Sonnet only): X% used"

// Exit cleanly
process({ action: "send-keys", sessionId: "...", literal: "/exit" })
process({ action: "send-keys", sessionId: "...", keys: ["Enter"] })
```

## Getting API Usage

If `CLAUDE_ADMIN_KEY` is set, use the included script:

```bash
./scripts/usage-report.sh [DAYS]
```

This generates an ASCII bar chart report of API costs over the specified period (default: 7 days).

Or query the API directly:

```bash
curl "https://api.anthropic.com/v1/organizations/cost_report?starting_at=YYYY-MM-DD" \
  --header "anthropic-version: 2023-06-01" \
  --header "x-api-key: $CLAUDE_ADMIN_KEY"
```

**Note:** This tracks **API billing costs** ($ spent), NOT subscription usage limits. For Max/Pro subscription limits, use the `/usage` command above.

**Known bug:** API may return 100x inflated values. Divide by 100 if needed.

## ccusage (Container Sessions Only)

`ccusage daily` shows Claude Code sessions **from this container only** — NOT global account usage. Use for tracking the agent's own "vibe coding" work:

```bash
ccusage daily --since 20260101
```

## Report Format

Use ASCII bar charts:

```
📊 Claude Usage Report

**Account Limits (Claude Max):**
• Session: 11% used (resets in 6h)
• Week (all models): 30% used (resets Feb 6)
• Week (Sonnet only): 1% used

**API Costs:** (if configured)
2026-01-31 : ██░░░░░░░░░░░░░░░░░░ $0.03
```

## Prerequisites

1. Claude Code CLI: `npm install -g @anthropic-ai/claude-code`
2. Authenticated: `~/.claude/.credentials.json` exists
3. (Optional) `CLAUDE_ADMIN_KEY` env var for API costs

## Example Prompts

User might ask:
- "How much Claude have I used?"
- "Show my Claude Max usage"
- "What are my weekly limits?"
- "Check my API costs for January"
- "Generate a usage report"

## Setting Up Cron (Optional)

For automated daily/weekly reports, create a cron job:

```json
{
  "name": "Claude Usage - Daily",
  "schedule": {"kind": "cron", "expr": "0 16 * * *", "tz": "UTC"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate Claude usage report and post to the appropriate channel.",
    "deliver": true
  }
}
```
