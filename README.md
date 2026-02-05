# OpenClaw Claude Usage Monitoring

**Autonomous usage monitoring system for Claude Max/Pro subscriptions with threshold-based conservation.**

## What This Does

Tracks Claude Max subscription usage across three dimensions:
1. **Session %** — Daily limit (resets 8am UTC)
2. **Week (all models) %** — Combined Opus + Sonnet weekly quota
3. **Week (Sonnet only) %** — Separate Sonnet-only pool

**Key Features:**
- ✅ Autonomous monitoring via PTY interaction with Claude Code
- ✅ Threshold detection (50%, 70%, 85% alerts)
- ✅ Historical trend analysis
- ✅ Conservation mode recommendations
- ✅ Fallback architecture support (Sonnet → Opus routing)

## Quick Start

### 1. Install Claude Code

```bash
# Install in container
docker exec <container> npm install -g @anthropic-ai/claude-code

# Authenticate (interactive)
docker exec -it <container> claude
# Follow OAuth flow, then /exit
```

### 2. Set Up Usage Tracker

```bash
chmod +x scripts/usage-tracker.py
```

### 3. Integrate into Heartbeat

The system uses OpenClaw's PTY mode to interact with Claude Code:

```javascript
// Start Claude with PTY
exec(command="claude --dangerously-skip-permissions", pty=true, background=true)
// Returns sessionId

// Accept warning (Down arrow, Enter)
process(action="send-keys", sessionId=ID, keys=["Down","Enter"])

// Run /usage command
process(action="write", sessionId=ID, data="/usage\n")

// Get output
process(action="log", sessionId=ID)

// Parse percentages and update tracker
python3 usage-tracker.py update <session%> <weekAll%> <weekSonnet%>

// Check thresholds
python3 usage-tracker.py check
```

### 4. Schedule Automated Checks

**Hourly Heartbeat:**
```json
{
  "name": "Heartbeat - Hourly",
  "schedule": {"kind": "cron", "expr": "0 * * * *", "tz": "America/Los_Angeles"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Check Claude Max usage via PTY, update tracker, and alert if thresholds crossed."
  }
}
```

**Daily Report (6 AM):**
```json
{
  "name": "Claude Usage - Daily",
  "schedule": {"kind": "cron", "expr": "0 6 * * *", "tz": "America/Los_Angeles"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate Claude usage daily report via PTY and post to #briefs.",
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
| 🟡 Caution | 50-69% | Monitor | Alert + track trends |
| 🟠 Warning | 70-84% | Reduce | Limit sub-agents, shorter responses |
| 🔴 Danger | 85-100% | Conserve | Minimal mode, rely on Sonnet fallback |

See `usage-conservation-strategy.md` for full playbook.

### Conservation Strategy

**🟢 Safe (<50%):**
- All systems go
- Nightly builds enabled
- Proactive work encouraged

**🟡 Caution (50-69%):**
- Post alert when threshold crossed
- Monitor trends daily
- Continue normal operations (Sonnet fallback available)

**🟠 Warning (70-84%):**
- Reduce sub-agent spawns (max 3 instead of 8)
- Shorter responses
- Skip non-essential proactive work
- Continue: briefs, heartbeats, critical work

**🔴 Danger (85-100%):**
- Minimal mode: essential operations only
- Pause: nightly builds, sub-agents, proactive content
- Shortened briefs
- Rely on Sonnet fallback (separate pool)

### Fallback Architecture

**Recommended setup:**
- Primary: Sonnet 4.5
- Fallback: Opus 4.5
- Heartbeats/Sub-agents: Sonnet 4.5 (explicit)

**Result:** Even if "All models" hits 100%, system can still operate on Sonnet's separate pool.

## Alert Protocol

When crossing threshold (50%, 70%, 85%), post to system channel:

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

## PTY Interaction Details

Claude Code's `/usage` command requires interactive terminal, but OpenClaw's PTY mode with `send-keys` makes automation possible:

### Starting Claude Code

```bash
# Start with PTY and background
exec(command="claude --dangerously-skip-permissions", pty=true, background=true)
# Returns sessionId
```

### Accepting Safety Warning

```bash
# Send Down arrow + Enter to accept warning
process(action="send-keys", sessionId=ID, keys=["Down","Enter"])
```

### Running /usage Command

```bash
# Send the command with newline
process(action="write", sessionId=ID, data="/usage\n")
```

### Getting Output

```bash
# Retrieve logs
process(action="log", sessionId=ID)
```

### Parsing Output

Look for lines like:
```
Session      : ████████░░░░░░░░░░░░ 40%
Week (all)   : ██████░░░░░░░░░░░░░░ 32%
Week (Sonnet): █░░░░░░░░░░░░░░░░░░░ 1%
```

Extract percentages and update tracker.

## Files

| File | Purpose |
|------|---------|
| `scripts/usage-tracker.py` | Core tracking + threshold detection |
| `scripts/check-claude-usage.sh` | Wrapper for heartbeat checks |
| `scripts/get-claude-usage.sh` | Helper for manual updates |
| `usage-conservation-strategy.md` | Full threshold playbook |
| `SKILL.md` | Skill instructions for OpenClaw agents |

## Known Issues

### Auth Persistence

Claude Code auth is lost on container restart. Either:
- Volume mount `~/.claude/` directory
- Re-authenticate after restart

### Weekly Reset Timing

Usage resets **Thursday 9:59 PM PST** (Friday 5:59 AM UTC).

Track days until reset in alerts to understand urgency.

### PTY Session Cleanup

Remember to clean up PTY sessions after use:

```bash
process(action="kill", sessionId=ID)
```

## License

MIT

Built for [OpenClaw](https://openclaw.ai) 🤖
