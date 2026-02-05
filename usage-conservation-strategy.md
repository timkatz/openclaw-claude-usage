# Claude Max Usage Conservation Strategy
*Updated: 2026-02-05 (Post-Fallback Architecture)*

## Current Architecture

**Model Routing:**
- **Primary:** Sonnet 4.5 (conserving Opus quota until Thursday reset)
- **Fallback:** Opus 4.5 (if Sonnet fails)
- **Heartbeats:** Sonnet 4.5 (explicit, 1h interval)
- **Sub-agents:** Sonnet 4.5 (explicit, max 8 concurrent)

**Quota Pools:**
- **All models:** 94% used (includes Opus + Sonnet combined)
- **Sonnet only:** 2% used (separate pool, 98% available)

**Reset Schedule:**
- **All models:** Thursday 9:59 PM PST
- **Sonnet only:** Same time, separate tracking

## Threshold System

| Threshold | Weekly % | Status | Action |
|-----------|----------|--------|--------|
| Safe | <50% | 🟢 | Normal operations |
| Caution | 50-69% | 🟡 | Monitor trends, alert Tim |
| Warning | 70-84% | 🟠 | Reduce non-essential work, alert Tim |
| Danger | 85-100% | 🔴 | Conservation mode, alert Tim immediately |

## Alert Protocol

**When crossing threshold (50%, 70%, 85%):**

Post to #system channel:
```
⚠️ Claude Max Usage Alert

**Status:** [Caution/Warning/Danger]
**Weekly (all models):** XX% used
**Weekly (Sonnet only):** X% used
**Days until reset:** X
**Burn rate:** ~X%/day

**Recommendation:** [see actions below]
```

## Conservation Actions by Threshold

### 🟢 Safe (<50%)
- Normal operations
- All features enabled
- Nightly builds run normally
- Proactive content generation

### 🟡 Caution (50-69%)
- **Monitor:** Daily trend analysis
- **Alert:** Notify Tim when threshold crossed
- **Continue:** Normal operations (we have fallback to Sonnet)
- **Track:** What activities are driving usage

### 🟠 Warning (70-84%)
- **Alert:** Post to #system immediately
- **Reduce:**
  - Limit sub-agent spawns (max 3 concurrent instead of 8)
  - Shorter responses (concise over comprehensive)
  - Skip non-essential proactive work
- **Continue:**
  - Morning/evening briefs (essential)
  - Heartbeats (already on Sonnet)
  - Critical client work
- **Switch:** If vibe coding, use Sonnet explicitly for routine tasks

### 🔴 Danger (85-100%)
- **Alert:** Post to #system + DM Tim immediately
- **Pause:**
  - Nightly builds (disable cron)
  - Sub-agent spawns
  - Proactive content generation
  - Long research tasks
- **Minimal mode:**
  - Morning brief (shortened format)
  - Evening brief (status only)
  - Heartbeats (essential checks only)
  - Direct questions only (no proactive work)
- **Strategy:** Rely on Sonnet fallback pool (98% available)

## New Reality: Fallback Architecture Advantage

**OLD (before Feb 5):**
- Hit 100% → completely blocked
- No fallback → dead in water

**NEW (with fallback + Sonnet default):**
- "All models" at 100% → Opus blocked
- Requests fall back to Sonnet automatically
- Sonnet pool at 2% → 98% headroom
- **Result:** Stay operational even when "All models" maxes out

**Implications:**
1. Less urgency when hitting 85%+ (we have Sonnet safety net)
2. Conservation mode is about preserving Opus for interactive use, not avoiding total shutdown
3. Heartbeats/sub-agents already on Sonnet → don't contribute to "All models" burnCONSERVATION IS ABOUT:
- Preserving Opus quota for Tim's vibe coding sessions
- Avoiding hitting Sonnet limit too (though we have 98% available)
- Smart resource allocation, not panic mode

## Tracking & Reporting

**Automated tracking:**
- **Script:** `/home/node/clawd/scripts/usage-tracker.py`
- **Update:** Daily at 6 AM PST (with morning brief)
- **Alert:** When crossing thresholds (50%, 70%, 85%)
- **Trend:** Weekly burn rate analysis

**Daily snapshot includes:**
- Session % (resets daily 8 AM UTC)
- Week (all) % (includes Opus + Sonnet)
- Week (Sonnet) % (Sonnet only pool)
- Status (safe/caution/warning/danger)

**Manual update when needed:**
```bash
python3 /home/node/clawd/scripts/usage-tracker.py update <session%> <weekAll%> <weekSonnet%>
```

**Check current status:**
```bash
python3 /home/node/clawd/scripts/usage-tracker.py check
python3 /home/node/clawd/scripts/usage-tracker.py trend
```

## PTY /usage Issue (Documented)

**Problem:** Claude Code's `/usage` command requires interactive terminal and doesn't work with pipes or scripts.

**Attempted:**
- `echo "/usage" | claude` → hangs
- PTY automation → times out
- Admin API → returns 404 (subscription accounts not supported)

**Current Solution:**
- Manual checks via Claude Code interactive session
- Daily cron updates tracking file at 6 AM
- Browser automation possible but not implemented (heavy)

**Future:** Could implement browser-based scraping of claude.ai/settings/usage if needed.

## What Actually Burns Quota

**High burn (Opus):**
- Long conversations with complex reasoning
- Vibe coding sessions (Claude Code)
- Multi-file refactoring
- Deep analysis tasks

**Medium burn (Sonnet):**
- Morning/evening briefs
- Sub-agent spawns (now on Sonnet)
- Heartbeat checks (now on Sonnet)
- Research and summarization

**Low burn:**
- Simple questions
- File reads
- Status checks
- Quick responses

**Zero burn:**
- Tool calls (exec, read, write)
- File operations
- External API calls

## Recovery Strategy

**When "All models" hits 100%:**
1. Automatic fallback to Sonnet kicks in
2. Monitor Sonnet pool (should be 98% available)
3. Continue essential operations on Sonnet
4. Preserve for:
   - Tim's direct questions
   - Critical client work
   - Emergency tasks
5. Wait for Thursday 9:59 PM reset

**When both pools max out (unlikely):**
1. Hard stop - truly blocked
2. Only happens if we burn through 98% of Sonnet pool
3. At current rates: Would take weeks
4. Emergency: Wait for weekly reset

## Post-Reset Actions

**Thursday 10 PM PST (after weekly reset):**
1. Verify reset via Claude Code `/usage`
2. Update tracking: `usage-tracker.py update 0 0 0`
3. Alert Tim in #briefs: "Weekly limit reset - full bandwidth restored"
4. Resume normal operations
5. Re-enable nightly builds if disabled
6. Switch primary model back to Opus (optional - Tim decides)

## Key Principle

**Smart allocation > Panic mode**

We have architectural resilience now. Use Opus when it matters, fall back to Sonnet when needed, conserve strategically, but don't shut down unnecessarily.

The goal is **continuous operation** with intelligent resource management.
