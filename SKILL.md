---
name: claude-max-usage
description: Generate Claude usage reports for OpenClaw. Reports global account usage (Max/Pro subscription limits via /usage command) and optionally API costs (via Admin API). Use when asked about Claude usage, costs, limits, or utilization.
---

# Claude Usage Reporting for OpenClaw

Report Claude usage from within OpenClaw.

## Prerequisites

1. Claude Code CLI installed: `npm install -g @anthropic-ai/claude-code`
2. Auth files present: `~/.claude/.credentials.json`
3. (Optional) Admin API key: `CLAUDE_ADMIN_KEY` env var for API cost reporting

## Global Account Usage (Claude Max/Pro)

Shows usage across your **entire Claude account** — all devices, web, mobile, desktop.

### Getting Usage

The `/usage` command only works interactively. Run Claude Code with PTY:

```javascript
// Start claude interactively
exec({ command: "claude", pty: true, yieldMs: 5000 })

// Send /usage command
process({ action: "send-keys", sessionId: "...", literal: "/usage" })
process({ action: "send-keys", sessionId: "...", keys: ["Enter"] })

// Poll and parse output
process({ action: "poll", sessionId: "..." })
// Look for: "Current session: X% used", "Current week (all models): X% used"

// Exit cleanly
process({ action: "send-keys", sessionId: "...", literal: "/exit" })
process({ action: "send-keys", sessionId: "...", keys: ["Enter"] })
```

### Output Format

```
Current session:           X% used (resets in Xh)
Current week (all models): X% used (resets [date])
Current week (Sonnet only): X% used (resets [date])
```

## API Usage (Optional)

If you also use the Anthropic API directly for your own applications:

```bash
curl "https://api.anthropic.com/v1/organizations/cost_report?starting_at=YYYY-MM-DD" \
  --header "anthropic-version: 2023-06-01" \
  --header "x-api-key: $CLAUDE_ADMIN_KEY"
```

**Known bug:** API may return values 100x higher than Console. Divide by 100 if needed.

## What About ccusage?

`ccusage` only shows Claude Code sessions from **this specific container** — useful if OpenClaw does its own "vibe coding" tasks. It does NOT show global account usage.

For global account limits, use `/usage` as described above.

## Report Format

Use ASCII bar charts:

```
📊 Claude Usage Report — [date]

**Account Limits (Claude Max):**
• Session: 11% used (resets in 6h)
• Week (all models): 30% used (resets Feb 6)

**API Costs:** (if applicable)
[date] : ██░░░░░░░░░░░░░░░░░░ $0.03
```

## Cron Setup

Create an OpenClaw cron job that:
1. Runs `claude` with PTY
2. Sends `/usage` and captures output
3. Optionally pulls API costs
4. Formats and posts report

See README.md for full cron job example.
