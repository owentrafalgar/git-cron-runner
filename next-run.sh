#!/bin/bash
CRON_LINE=$(grep -v '^\s*#' /etc/cron.d/job | grep -v '^\s*$' | head -1)
CRON_EXPR=$(echo "$CRON_LINE" | awk '{print $1, $2, $3, $4, $5}')

NEXT=$(python3 -c "
from croniter import croniter
from datetime import datetime
base = datetime.now()
itr = croniter('$CRON_EXPR', base)
print(itr.get_next(datetime).strftime('%Y-%m-%d %H:%M:%S %A'))
")

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Next scheduled run: $NEXT"
