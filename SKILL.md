---
name: claude-max-usage
description: Generate Claude Max subscription utilization reports via the Anthropic Admin API. Use when asked to track Claude usage, generate cost reports, show API spending, or analyze Claude Max ROI. Requires CLAUDE_ADMIN_KEY environment variable.
---

# Claude Max Usage Reporting

Generate utilization reports for Claude Max subscriptions showing theoretical API costs vs the flat monthly rate.

## Prerequisites

1. **Admin API Key** — Get from https://console.anthropic.com → Settings → Admin API Keys
2. **Environment Variable** — Set `CLAUDE_ADMIN_KEY` with your admin key

## Quick Start

Run the bundled script:

```bash
./scripts/usage-report.sh [days]
```

- Default: 7 days
- For monthly: `./scripts/usage-report.sh 30`

## API Details

**Endpoint:**
```bash
curl -s "https://api.anthropic.com/v1/organizations/cost_report?starting_at=YYYY-MM-DD" \
  --header "anthropic-version: 2023-06-01" \
  --header "x-api-key: $CLAUDE_ADMIN_KEY"
```

**Response:** Paginated daily costs (7 days per page). Use `has_more` and `next_page` for pagination.

**Note:** Returns "theoretical API cost" — what you'd pay without Max. Compare against $200/month to show ROI.

## Report Format

Use ASCII bar charts for visual appeal:

```
📊 Claude Max Utilization Report

Last 7 Days:
2026-01-25 : ██████████ $5.51
2026-01-26 : █████████░ $5.28
2026-01-27 : █████░░░░░ $2.80

Weekly Total: $28.02
Daily Average: $4.00
Projected Monthly: $120.07

Max Plan: $200/month
📉 Under-utilizing (60% of plan value)
```

**ASCII charts > markdown tables** — more readable in chat interfaces.

## Scheduling Recommendations

| Report | Schedule | Content |
|--------|----------|---------|
| Daily | 8 AM local | Yesterday's usage, weekly running total |
| Weekly | Mondays | Prior week breakdown, patterns |
| Monthly | 1st of month | Full month, ROI analysis |

## Interpreting Results

- **>100% of plan value** = Max is saving money ✅
- **60-100%** = Good utilization, room to use more
- **<60%** = Consider if Max is worth it for this user

## Limitations

- Admin API shows aggregated costs, not per-workspace breakdown (workspace_id may be null)
- Separate API keys (e.g., for production apps) may need separate admin keys
- Data is delayed ~24 hours
