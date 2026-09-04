#!/bin/bash
set -eu

CRON_SCHEDULE="${CRON_SCHEDULE:-0 3 * * 0}"

echo "${CRON_SCHEDULE} /run.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/job
chmod 0644 /etc/cron.d/job
crontab /etc/cron.d/job
touch /var/log/cron.log

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Container started" >> /var/log/cron.log
/next-run.sh >> /var/log/cron.log

cron
tail -f /var/log/cron.log
