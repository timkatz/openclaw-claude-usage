# OpenClaw Claude Usage Monitoring

**Autonomous usage monitoring system for Claude Max/Pro subscriptions with threshold-based conservation.**

## What This Does

Tracks your Claude Max subscription usage across three dimensions:
1. **Session %** — Daily limit (resets 8am UTC)
2. **Week (all models) %** — Combined Opus + Sonnet weekly quota
3. **Week (Sonnet only) %** — Separate Sonnet-only pool

**Key Features:**
- ✅ Autonomous monitoring via browser automation (no manual checks)
- ✅ Threshold detection (50%, 70%, 85% alerts)
- ✅ Historical trend analysis
- ✅ Conservation mode recommendations
- ✅ Fallback architecture support (Sonnet → Opus routing)

## Quick Start

### 1. Install Dependencies

```bash
# Python script needs no external deps (stdlib only)
chmod +x scripts/usage-tracker.py
```

### 2. Set Up Browser Automation

**Option A: Chrome Extension Relay (Recommended)**

Uses OpenClaw's browser relay with your existing logged-in Chrome session:

1. Open https://claude.ai/settings/usage in Chrome
2. Click OpenClaw Browser Relay extension → Badge ON
3. Run scraper via OpenClaw agent:
   ```javascript
   // Agent will use browser tool with profile="chrome"
   ```

**Option B: PTY Interactive (Manual)**

Claude Code's `/usage` command works interactively but not in scripts:

```bash
# Interactive only (PTY required)
docker exec -it openclaw-kai claude
/usage
# Manually update tracker with values shown
python3 scripts/usage-tracker.py update <session%> <weekAll%> <weekSonnet%>
```

### 3. Integrate into Heartbeat

Add to `HEARTBEAT.md`:

```markdown
## Claude Max Usage Monitoring (EVERY HEARTBEAT)

**Check every heartbeat** (hourly during waking hours):

```bash
# Check for threshold alerts
ALERT=$(python3 /home/node/clawd/scripts/usage-tracker.py check)
if [[ "$ALERT" == ALERT:* ]]; then
    # Post alert to #system
fi
```

See full protocol in HEARTBEAT.md template below.
```

### 4. Schedule Daily Updates

Cron job to scrape usage daily:

```json
{
  "name": "Claude Usage - Daily Check",
  "schedule": {"kind": "cron", "expr": "0 14 * * *", "tz": "America/Los_Angeles"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Scrape claude.ai/settings/usage using browser relay and update usage tracker.",
    "deliver": true
  }
}
```

## The System

### usage-tracker.py

Core Python script for tracking, threshold detection, and trends:

```bash
# Update with new snapshot
python3 usage-tracker.py update <session%> <weekAll%> <weekSonnet%>

# Check for threshold alerts
python3 usage-tracker.py check
# Output: ALERT:caution / ALERT:warning / ALERT:danger / OK

# Show recent trend
python3 usage-tracker.py trend

# Show full history
python3 usage-tracker.py history
```

**Data files:**
- `memory/usage-checks.json` — Current snapshot
- `memory/claude-usage-history.jsonl` — Historical log

### Threshold System

| Level | Weekly % | Status | Action |
|-------|----------|--------|--------|
| 🟢 Safe | <50% | Normal | All systems go |
| 🟡 Caution | 50-69% | Monitor | Alert Tim, track trends |
| 🟠 Warning | 70-84% | Reduce | Limit sub-agents, shorter responses |
| 🔴 Danger | 85-100% | Conserve | Minimal mode, rely on Sonnet fallback |

See `usage-conservation-strategy.md` for full playbook.

### Conservation Strategy

**🟢 Safe (<50%):**
- All systems go
- Nightly builds enabled
- Proactive work encouraged

**🟡 Caution (50-69%):**
- Alert Tim when threshold crossed
- Monitor trends daily
- Continue normal operations (we have Sonnet fallback)

**🟠 Warning (70-84%):**
- Reduce sub-agent spawns (max 3 instead of 8)
- Shorter responses
- Skip non-essential proactive work
- Continue: briefs, heartbeats, critical work

**🔴 Danger (85-100%):**
- Minimal mode: essential operations only
- Pause: nightly builds, sub-agents, proactive content
- Shortened briefs
- Rely on Sonnet fallback (98% available)

### Fallback Architecture

**Since Feb 5, 2026:**
- Primary: Sonnet 4.5
- Fallback: Opus 4.5
- Heartbeats/Sub-agents: Sonnet 4.5 (explicit)

**Result:** Even if "All models" hits 100%, we can still operate on Sonnet's separate pool.

## Alert Protocol

When crossing threshold (50%, 70%, 85%), post to #system:

```
⚠️ Claude Max Usage Alert

**Status:** [Caution/Warning/Danger]
**Weekly (all models):** XX% used
**Weekly (Sonnet only):** X% used
**Days until reset:** X (Thursday 9:59 PM PST)
**Burn rate:** ~X%/day

**Recommendation:** [see conservation strategy]

**Fallback safety net:** Sonnet pool at X% (98% available for fallback)
```

## Why Browser Automation?

**Problem:** Claude Code's `/usage` command requires true PTY (interactive terminal) and doesn't work with piped/scripted automation.

**Solution:** Scrape https://claude.ai/settings/usage using OpenClaw's browser tool with Chrome extension relay. Uses Tim's existing logged-in session — no credentials needed.

**Benefits:**
- ✅ Fully autonomous (no manual checks)
- ✅ No credential management
- ✅ Uses existing logged-in session
- ✅ Reliable (page structure is stable)

## Files

| File | Purpose |
|------|---------|
| `scripts/usage-tracker.py` | Core tracking + threshold detection |
| `scripts/check-claude-usage.sh` | Wrapper for heartbeat checks |
| `scripts/get-claude-usage.sh` | Helper for manual updates |
| `usage-conservation-strategy.md` | Full threshold playbook |
| `SKILL.md` | Skill instructions for OpenClaw agents |

## HEARTBEAT.md Template

Add this to your `HEARTBEAT.md`:

```markdown
## Claude Max Usage Monitoring (HEARTBEAT CHECK)

**Check every heartbeat** (hourly during waking hours):

### How to Check

**Browser automation (primary):**
```bash
# Agent uses browser tool with profile="chrome"
# Scrapes claude.ai/settings/usage
# Parses values and updates tracker
```

**Manual update fallback:**
```bash
# After running /usage in Claude Code interactive, update tracker:
python3 /home/node/clawd/scripts/usage-tracker.py update <session%> <weekAll%> <weekSonnet%>
```

### What to Monitor
- **Session %** — resets daily at 8am UTC
- **Week (all) %** — Opus + Sonnet combined
- **Week (Sonnet) %** — Sonnet-only pool (separate)

### Threshold Detection

```bash
# During heartbeat, check if we crossed a threshold
ALERT=$(python3 /home/node/clawd/scripts/usage-tracker.py check)
if [[ "$ALERT" == ALERT:* ]]; then
    # Post alert to #system
    LEVEL=${ALERT#ALERT:}  # caution/warning/danger
    # Generate and send alert message
fi
```

### Alert Format

When crossing threshold (50%, 70%, 85%), post to #system (1467262769362505845):

```
⚠️ Claude Max Usage Alert

**Status:** [Caution/Warning/Danger]
**Weekly (all models):** XX% used
**Weekly (Sonnet only):** X% used
**Days until reset:** X (Thursday 9:59 PM PST)
**Burn rate:** ~X%/day

**Recommendation:** [see conservation strategy]

**Fallback safety net:** Sonnet pool at X% (98% available for fallback)
```

### Conservation Actions

**🟢 Safe (<50%):** All systems go
**🟡 Caution (50-69%):** Alert + monitor
**🟠 Warning (70-84%):** Reduce sub-agents, shorter responses
**🔴 Danger (85-100%):** Minimal mode, essentials only

Full playbook: `memory/usage-conservation-strategy.md`
```

## Known Issues

### PTY /usage Limitation

Claude Code's `/usage` command doesn't work with piped/scripted automation:

```bash
# ❌ This doesn't work
echo "/usage" | claude

# ❌ This doesn't work
claude < usage.txt

# ✅ This works (interactive PTY)
docker exec -it container claude
/usage
```

**Workaround:** Browser automation via OpenClaw relay (see above).

### Weekly Reset Timing

Usage resets **Thursday 9:59 PM PST** (Friday 5:59 AM UTC).

Track days until reset in alerts to help Tim understand urgency.

## License

MIT

Built for [OpenClaw](https://openclaw.ai) 🤖
