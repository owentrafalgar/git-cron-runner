#!/bin/bash
# Read the schedule from the active crontab, skipping comments,
# empty lines and variable assignments like SHELL=/bin/bash
CRON_LINE=$(crontab -l 2>/dev/null | grep -Ev '^\s*(#|$|[A-Za-z_]+=)' | head -1)
CRON_EXPR=$(echo "$CRON_LINE" | awk '{print $1, $2, $3, $4, $5}')

# Pass the expression as an argument instead of embedding it in the Python code
NEXT=$(python3 - "$CRON_EXPR" <<'PY'
import sys
from croniter import croniter
from datetime import datetime
itr = croniter(sys.argv[1], datetime.now())
print(itr.get_next(datetime).strftime('%Y-%m-%d %H:%M:%S %A'))
PY
)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Next scheduled run: $NEXT"
