#!/usr/bin/env python3
"""
Claude Max Usage Tracker
Manages daily snapshots, trend analysis, and threshold alerts
"""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

TRACKING_FILE = Path("/home/node/clawd/memory/usage-checks.json")
HISTORY_FILE = Path("/home/node/clawd/memory/claude-usage-history.jsonl")

def update_usage(session, week_all, week_sonnet):
    """Update current usage and append to history"""
    timestamp = datetime.now(timezone.utc).isoformat()
    date = datetime.now().strftime("%Y-%m-%d")
    
    # Determine status
    if week_all >= 85:
        status = "danger"
    elif week_all >= 70:
        status = "warning"
    elif week_all >= 50:
        status = "caution"
    else:
        status = "safe"
    
    # Update current tracking
    current = {
        "lastCheck": timestamp,
        "session": session,
        "weekAll": week_all,
        "weekSonnet": week_sonnet,
        "status": status
    }
    
    TRACKING_FILE.write_text(json.dumps(current, indent=2))
    
    # Append to history
    history_entry = {
        "date": date,
        "time": timestamp,
        "session": session,
        "weekAll": week_all,
        "weekSonnet": week_sonnet,
        "status": status
    }
    
    with HISTORY_FILE.open('a') as f:
        f.write(json.dumps(history_entry) + '\n')
    
    print(f"Updated: {status} ({week_all}% all, {week_sonnet}% sonnet)")
    return status

def check_thresholds():
    """Check if we crossed a threshold"""
    if not TRACKING_FILE.exists():
        print("No tracking data")
        return None
    
    current = json.loads(TRACKING_FILE.read_text())
    week_all = current['weekAll']
    status = current['status']
    
    # Get previous reading
    prev_week_all = 0
    if HISTORY_FILE.exists():
        lines = HISTORY_FILE.read_text().strip().split('\n')
        if len(lines) >= 2:
            prev = json.loads(lines[-2])
            prev_week_all = prev['weekAll']
    
    # Check threshold crossings
    if week_all >= 85 and prev_week_all < 85:
        print("ALERT:danger")
        return "danger"
    elif week_all >= 70 and prev_week_all < 70:
        print("ALERT:warning")
        return "warning"
    elif week_all >= 50 and prev_week_all < 50:
        print("ALERT:caution")
        return "caution"
    
    print(f"OK:{status}")
    return None

def generate_trend_report():
    """Generate trend analysis"""
    if not HISTORY_FILE.exists():
        print("No history data")
        return
    
    lines = HISTORY_FILE.read_text().strip().split('\n')
    recent = [json.loads(line) for line in lines[-7:]]  # Last 7 days
    
    print("=== WEEKLY TREND ===")
    for entry in recent:
        print(f"{entry['date']}: All={entry['weekAll']}% Sonnet={entry['weekSonnet']}% [{entry['status']}]")
    
    if len(recent) >= 2:
        print("\n=== DAILY BURN RATE ===")
        first = recent[0]['weekAll']
        last = recent[-1]['weekAll']
        delta = last - first
        days = len(recent)
        avg_daily = delta / days if days > 0 else 0
        
        print(f"{days}-day delta: +{delta}% (avg +{avg_daily:.1f}%/day)")
        
        if avg_daily > 0:
            remaining = 100 - last
            days_left = remaining / avg_daily
            print(f"Days to 100%: ~{days_left:.1f} days (if trend continues)")
        
        # Sonnet trend
        first_sonnet = recent[0]['weekSonnet']
        last_sonnet = recent[-1]['weekSonnet']
        sonnet_delta = last_sonnet - first_sonnet
        print(f"\nSonnet trend: {first_sonnet}% → {last_sonnet}% ({sonnet_delta:+}%)")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: usage-tracker.py {update|check|trend} [session% weekAll% weekSonnet%]")
        sys.exit(1)
    
    action = sys.argv[1]
    
    if action == "update":
        if len(sys.argv) != 5:
            print("Usage: usage-tracker.py update <session%> <weekAll%> <weekSonnet%>")
            sys.exit(1)
        session = int(sys.argv[2])
        week_all = int(sys.argv[3])
        week_sonnet = int(sys.argv[4])
        update_usage(session, week_all, week_sonnet)
    
    elif action == "check":
        check_thresholds()
    
    elif action == "trend":
        generate_trend_report()
    
    else:
        print(f"Unknown action: {action}")
        sys.exit(1)
