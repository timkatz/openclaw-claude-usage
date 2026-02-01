#!/bin/bash
# Claude Max Usage Report Generator
# Requires: CLAUDE_ADMIN_KEY environment variable

set -e

DAYS=${1:-7}
MAX_PLAN_COST=200

if [ -z "$CLAUDE_ADMIN_KEY" ]; then
    echo "Error: CLAUDE_ADMIN_KEY environment variable not set"
    echo "Get your admin key from: https://console.anthropic.com → Settings → Admin API Keys"
    exit 1
fi

# Calculate date range
if [[ "$OSTYPE" == "darwin"* ]]; then
    START_DATE=$(date -v-${DAYS}d +%Y-%m-%d)
    END_DATE=$(date +%Y-%m-%d)
else
    START_DATE=$(date -d "${DAYS} days ago" +%Y-%m-%d)
    END_DATE=$(date +%Y-%m-%d)
fi

echo "📊 Claude Max Utilization Report"
echo "Period: $START_DATE to $END_DATE ($DAYS days)"
echo ""

# Fetch all pages of data
ALL_DATA=""
NEXT_PAGE=""
PAGE=1

while true; do
    if [ -z "$NEXT_PAGE" ]; then
        URL="https://api.anthropic.com/v1/organizations/cost_report?starting_at=${START_DATE}&ending_at=${END_DATE}"
    else
        URL="https://api.anthropic.com/v1/organizations/cost_report?starting_at=${START_DATE}&ending_at=${END_DATE}&page=${NEXT_PAGE}"
    fi
    
    RESPONSE=$(curl -s "$URL" \
        --header "anthropic-version: 2023-06-01" \
        --header "x-api-key: $CLAUDE_ADMIN_KEY")
    
    # Check for error
    if echo "$RESPONSE" | grep -q '"type":"error"'; then
        echo "API Error: $RESPONSE"
        exit 1
    fi
    
    # Extract data
    PAGE_DATA=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for day in data.get('data', []):
    date = day['starting_at'][:10]
    amount = sum(float(r['amount']) for r in day.get('results', []))
    print(f'{date}|{amount:.2f}')
" 2>/dev/null || echo "")
    
    ALL_DATA="${ALL_DATA}${PAGE_DATA}"$'\n'
    
    # Check for more pages
    HAS_MORE=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('has_more', False))" 2>/dev/null || echo "False")
    
    if [ "$HAS_MORE" = "True" ]; then
        NEXT_PAGE=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('next_page', ''))" 2>/dev/null || echo "")
        ((PAGE++))
    else
        break
    fi
done

# Process and display
echo "$ALL_DATA" | grep -v '^$' | sort | while IFS='|' read -r DATE AMOUNT; do
    # Generate ASCII bar (max 20 chars, scale based on $10 = full bar)
    BAR_LEN=$(echo "$AMOUNT" | python3 -c "import sys; a=float(sys.stdin.read().strip()); print(min(20, int(a/0.5)))" 2>/dev/null || echo "0")
    BAR=$(printf '█%.0s' $(seq 1 $BAR_LEN 2>/dev/null) || echo "")
    EMPTY=$((20 - BAR_LEN))
    [ $EMPTY -gt 0 ] && BAR="${BAR}$(printf '░%.0s' $(seq 1 $EMPTY))"
    
    echo "$DATE : $BAR \$$AMOUNT"
done

echo ""

# Calculate totals
TOTAL=$(echo "$ALL_DATA" | grep -v '^$' | cut -d'|' -f2 | python3 -c "import sys; print(f'{sum(float(l) for l in sys.stdin):.2f}')" 2>/dev/null || echo "0.00")
DAILY_AVG=$(echo "$TOTAL $DAYS" | python3 -c "import sys; t,d=sys.stdin.read().split(); print(f'{float(t)/int(d):.2f}')" 2>/dev/null || echo "0.00")
PROJECTED=$(echo "$DAILY_AVG" | python3 -c "import sys; print(f'{float(sys.stdin.read().strip())*30:.2f}')" 2>/dev/null || echo "0.00")
UTILIZATION=$(echo "$PROJECTED $MAX_PLAN_COST" | python3 -c "import sys; p,m=sys.stdin.read().split(); print(f'{(float(p)/float(m))*100:.0f}')" 2>/dev/null || echo "0")

echo "**Total:** \$$TOTAL"
echo "**Daily Average:** \$$DAILY_AVG"
echo "**Projected Monthly:** \$$PROJECTED"
echo ""
echo "**Max Plan:** \$$MAX_PLAN_COST/month"

if [ "$UTILIZATION" -gt 100 ]; then
    SAVINGS=$(echo "$PROJECTED $MAX_PLAN_COST" | python3 -c "import sys; p,m=sys.stdin.read().split(); print(f'{float(p)-float(m):.2f}')" 2>/dev/null || echo "0.00")
    echo "✅ Saving \$$SAVINGS vs pay-per-use ($UTILIZATION% utilization)"
elif [ "$UTILIZATION" -gt 60 ]; then
    echo "📊 Good utilization ($UTILIZATION% of plan value)"
else
    echo "📉 Under-utilizing ($UTILIZATION% of plan value)"
fi
