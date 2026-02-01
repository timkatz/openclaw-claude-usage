# Claude Usage Reporting Skill

Track and report Claude usage across **two separate billing systems**:
1. **Claude Max/Pro Subscription** — Flat monthly rate with usage limits
2. **Claude API** — Pay-per-use token billing

## ⚠️ Important: Two Separate Systems

Anthropic has **two completely different billing systems** that don't share data:

| System | Billing | How to Track | What It Shows |
|--------|---------|--------------|---------------|
| **Claude Max/Pro** | $20-200/month flat | Claude Code `/usage` command | % of weekly limit used |
| **Claude API** | Pay-per-token | Admin API + Console | $ cost per day |

**You cannot see subscription usage via the Admin API, and you cannot see API costs via Claude Code.**

---

## Part 1: Claude Max/Pro Subscription Usage

For personal Claude Max ($200/mo) or Pro ($20/mo) plans.

### How to Check Usage

**Option A: Claude Code CLI (interactive)**
```bash
claude
# Then type: /usage
```

Shows:
- Current session % used
- Current week (all models) % used  
- Current week (Sonnet only) % used

**Option B: ccusage CLI (historical)**
```bash
npx ccusage@latest daily --since 20260101
```

Shows token counts and estimated costs from local session logs.

**Option C: Third-party tools**
- [claude-usage-tool](https://github.com/IgniteStudiosLtd/claude-usage-tool) — macOS menu bar app
- [Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor) — Real-time CLI

### Key Points
- Usage is tracked as **% of weekly limits**, not dollars
- Limits reset on a rolling basis (different for session vs weekly)
- Usage data is stored locally in `~/.claude/` directory
- **Admin API cannot see this data** — it's subscription-only

---

## Part 2: Claude API Usage (Pay-Per-Use)

For direct API calls (production apps, integrations, etc.)

### Setup

1. Get an **Admin API Key** from https://console.anthropic.com → Settings → Admin API Keys
2. Set environment variable:
```bash
export CLAUDE_ADMIN_KEY="sk-ant-admin..."
```

### How to Check Usage

**Via Admin API:**
```bash
curl "https://api.anthropic.com/v1/organizations/cost_report?starting_at=2026-01-01" \
  --header "anthropic-version: 2023-06-01" \
  --header "x-api-key: $CLAUDE_ADMIN_KEY"
```

**Via Console:**
https://console.anthropic.com → Analytics → Cost

### Key Points
- Shows **actual dollar costs** per day
- Can group by model, workspace, description
- Data is delayed ~24 hours
- **Does NOT include subscription usage** (Claude Max/Pro)

---

## Example Report Formats

### Subscription Usage (from /usage)
```
📊 Claude Max Usage

Current session:           11% used (resets in 6h)
Current week (all models): 30% used (resets Feb 6)
Current week (Sonnet):     1% used (resets Feb 7)
```

### API Usage (from Admin API)
```
📊 Claude API Cost Report

Last 7 Days:
2026-01-25 : ██████████ $0.06
2026-01-26 : █████████░ $0.05
2026-01-27 : █████░░░░░ $0.03

Weekly Total: $0.21
```

---

## Scripts

### `scripts/usage-report.sh`
Pulls API costs from the Admin API. Requires `CLAUDE_ADMIN_KEY`.

```bash
./scripts/usage-report.sh [days]
```

### For Subscription Usage
The `/usage` command is **interactive only** — it cannot be automated via `claude -p`. 

To track subscription usage programmatically:
1. Use `ccusage` to read local JSONL files
2. Or build a wrapper that parses the interactive output

---

## Scheduling Recommendations

| Report | Schedule | Source | Content |
|--------|----------|--------|---------|
| Daily | 8 AM | Admin API | API costs from yesterday |
| Weekly | Mondays | Both | API costs + subscription % |
| Monthly | 1st | Admin API | Full month ROI analysis |

---

## Known Issues

### Admin API 100x Discrepancy
We've observed the Admin API returning values ~100x higher than the Console shows for the same date range. This may be a bug in Anthropic's API. The Console is considered authoritative.

### Subscription Usage Not in API
There is currently no API to retrieve Claude Max/Pro subscription usage programmatically. The only methods are:
- Interactive `/usage` command in Claude Code
- Local JSONL files via `ccusage`
- Third-party tools that scrape the web UI

---

## License

MIT

---

Built by [Kai](https://github.com/dyodeinc) 🤖
