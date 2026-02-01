---
name: claude-max-usage
description: Generate Claude usage reports for both subscription plans (Max/Pro) and API usage. Use when asked to track Claude usage, show costs, check limits, or analyze utilization. Note: Subscription usage (% limits) and API usage ($ costs) are tracked separately by Anthropic.
---

# Claude Usage Reporting

Generate utilization reports for Claude. **Important:** Anthropic has two separate systems:

1. **Subscription (Max/Pro)** — Usage tracked as % of weekly limits
2. **API (pay-per-use)** — Usage tracked as $ costs

## Subscription Usage (Claude Max/Pro)

For personal subscription plans. Shows % of weekly limits used.

**Interactive method (Claude Code):**
```bash
claude
# Then type: /usage
```

**Historical method (ccusage):**
```bash
npx ccusage@latest daily --since 20260101
```

**Output format:**
```
Current session:           11% used
Current week (all models): 30% used
Current week (Sonnet):     1% used
```

**Note:** `/usage` is interactive only — cannot be automated via `claude -p`.

## API Usage (Pay-Per-Use)

For direct API calls. Shows actual $ costs.

**Requires:** `CLAUDE_ADMIN_KEY` environment variable (Admin API key from Console)

**Endpoint:**
```bash
curl "https://api.anthropic.com/v1/organizations/cost_report?starting_at=YYYY-MM-DD" \
  --header "anthropic-version: 2023-06-01" \
  --header "x-api-key: $CLAUDE_ADMIN_KEY"
```

**Or run bundled script:**
```bash
./scripts/usage-report.sh [days]
```

**Output format (use ASCII charts):**
```
📊 Claude API Cost Report

2026-01-25 : ██████████ $0.06
2026-01-26 : █████████░ $0.05

Weekly Total: $0.21
```

## Report Formats

**ASCII bar charts > markdown tables** — more readable in chat.

## Key Differences

| Aspect | Subscription | API |
|--------|--------------|-----|
| Billing | Flat monthly | Per token |
| Metric | % of limit | $ cost |
| Data source | Local + /usage | Admin API |
| Automation | Limited | Full API |
