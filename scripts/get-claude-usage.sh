#!/bin/bash
# Simple wrapper to extract /usage from Claude Code
# Uses a workaround: check if we can get info from .claude config or recent sessions

set -e

OUTPUT_FILE="/home/node/clawd/memory/usage-checks.json"
TEMP_OUTPUT="/tmp/claude-usage-raw.txt"

# Method 1: Try to use script command to capture PTY session
(
    # Start claude in a pseudo-terminal
    echo "/usage"
    sleep 3
    echo "/exit"
    sleep 1
) | timeout 15 script -q -c "claude --dangerously-skip-permissions" "$TEMP_OUTPUT" 2>&1 || true

# Parse the output
if [ -f "$TEMP_OUTPUT" ]; then
    # Look for percentage patterns
    SESSION_PCT=$(grep -oP 'Session[^\n]*?(\d+)%' "$TEMP_OUTPUT" | grep -oP '\d+' | head -1 || echo "0")
    WEEK_ALL_PCT=$(grep -oP 'Week.*?all[^\n]*?(\d+)%' "$TEMP_OUTPUT" | grep -oP '\d+' | head -1 || echo "0")
    WEEK_SONNET_PCT=$(grep -oP '(Week.*?Sonnet|Sonnet only)[^\n]*?(\d+)%' "$TEMP_OUTPUT" | grep -oP '\d+' | tail -1 || echo "0")
    
    if [ "$WEEK_ALL_PCT" != "0" ]; then
        # Success! Update tracking file
        python3 /home/node/clawd/scripts/usage-tracker.py update "$SESSION_PCT" "$WEEK_ALL_PCT" "$WEEK_SONNET_PCT"
        echo "✓ Usage updated: $WEEK_ALL_PCT% all, $WEEK_SONNET_PCT% sonnet"
        exit 0
    fi
fi

# If that didn't work, fall back to reading last known values
if [ -f "$OUTPUT_FILE" ]; then
    cat "$OUTPUT_FILE"
    echo "⚠ Using cached data - PTY method failed" >&2
    exit 1
else
    echo "❌ No usage data available" >&2
    exit 1
fi
