# Claude Max Usage Reporting Skill

A Claude/OpenClaw skill for generating utilization reports for Claude Max subscriptions. Shows theoretical API costs vs your $200/month flat rate to track ROI.

## Example Output

```
📊 Claude Max Utilization Report
Period: 2026-01-25 to 2026-01-31 (7 days)

2026-01-25 : ██████████░░░░░░░░░░ $5.51
2026-01-26 : █████████░░░░░░░░░░░ $5.28
2026-01-27 : █████░░░░░░░░░░░░░░░ $2.80
2026-01-28 : █████░░░░░░░░░░░░░░░ $2.97
2026-01-29 : ██████████░░░░░░░░░░ $5.55
2026-01-30 : █████░░░░░░░░░░░░░░░ $2.94
2026-01-31 : █████░░░░░░░░░░░░░░░ $2.96

**Total:** $28.02
**Daily Average:** $4.00
**Projected Monthly:** $120.07

**Max Plan:** $200/month
📊 Good utilization (60% of plan value)
```

## Setup

### 1. Get an Admin API Key

1. Go to https://console.anthropic.com
2. Navigate to Settings → Admin API Keys
3. Create a new key with read access

### 2. Set Environment Variable

```bash
export CLAUDE_ADMIN_KEY="your-admin-key-here"
```

Or add to your `.env` file.

## Usage

### As a Claude Skill

Add this skill to your Claude/OpenClaw setup. Then ask:
- "Generate a Claude usage report"
- "How much have I used Claude this week?"
- "Show my Claude Max ROI"

### Standalone Script

```bash
# Last 7 days (default)
./scripts/usage-report.sh

# Last 30 days
./scripts/usage-report.sh 30

# Full month
./scripts/usage-report.sh 31
```

## Scheduling Recommendations

| Report | Schedule | Use Case |
|--------|----------|----------|
| Daily | 8 AM | Track yesterday's usage |
| Weekly | Mondays | Week-over-week trends |
| Monthly | 1st of month | Full ROI analysis |

## Understanding the Numbers

The Anthropic Admin API returns **theoretical API costs** — what you would pay if you were on pay-per-use pricing instead of the Max subscription.

- **>100% utilization** = Max is saving you money ✅
- **60-100%** = Good value, room to use more
- **<60%** = Consider if Max is right for you

## Limitations

- Data is delayed ~24 hours
- Workspace breakdown may not be available (depends on your setup)
- Separate API keys (e.g., production apps) need separate admin access

## License

MIT

---

Built by [Kai](https://github.com/dyodeinc) 🤖
