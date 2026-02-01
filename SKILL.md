---
name: claude-max-usage
description: Generate Claude usage reports for OpenClaw. Reports both subscription usage (Max/Pro via ccusage) and API costs (via Admin API). Use when asked about Claude usage, costs, limits, or utilization. Requires Claude Code CLI installed and authenticated in the container.
---

# Claude Usage Reporting for OpenClaw

Report Claude usage across both billing systems.

## Prerequisites

Before using this skill, ensure:
1. Claude Code CLI installed: `npm install -g @anthropic-ai/claude-code`
2. ccusage installed: `npm install -g ccusage`
3. Auth files present: `~/.claude/.credentials.json`
4. Admin API key set: `CLAUDE_ADMIN_KEY` env var

## Two Separate Systems

| System | Command | Output |
|--------|---------|--------|
| Subscription (Max/Pro) | `ccusage daily` | Tokens + theoretical $ |
| API (pay-per-use) | Admin API curl | Actual $ costs |

## Subscription Usage

Run ccusage for historical token data:

```bash
# Daily
ccusage daily --since 20260101

# Weekly  
ccusage weekly

# Monthly
ccusage monthly
```

**Note:** `/usage` command only works interactively in Claude Code, not via scripts.

## API Usage

```bash
curl "https://api.anthropic.com/v1/organizations/cost_report?starting_at=YYYY-MM-DD" \
  --header "anthropic-version: 2023-06-01" \
  --header "x-api-key: $CLAUDE_ADMIN_KEY"
```

**Known bug:** API returns values 100x higher than Console. Divide by 100.

## Report Format

Use ASCII bar charts, not tables:

```
📊 Claude Usage Report — [date]

**Subscription (Claude Max):**
[date] : ██████████░░░░░░░░░░ $X.XX
         XX,XXX tokens

**API Usage:**
[date] : ██░░░░░░░░░░░░░░░░░░ $X.XX

**Combined:** $X.XX theoretical
```

## For Current Limits

To get live `/usage` data, run claude interactively with PTY:

```javascript
exec({ command: "claude", pty: true })
// send-keys: "/usage", then "Enter"
// parse output for percentages
```

## Container Setup

If auth is missing, the container needs:
```bash
# From host:
docker cp ~/.claude <container>:/home/node/.claude

# Or volume mount in docker-compose:
volumes:
  - ./host/.claude:/home/node/.claude
```
