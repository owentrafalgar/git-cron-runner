#!/bin/bash
set -eu

CRON_SCHEDULE="${CRON_SCHEDULE:-0 3 * * 0}"

# Cron does not pass the container environment to jobs.
# Dump all env vars to a file that the cron job sources before running.
# Restrict permissions because the file contains the Git token.
export -p > /container.env
chmod 600 /container.env

# Write the crontab to a temp file (not /etc/cron.d, which expects a user field)
cat > /tmp/job.cron <<EOF
SHELL=/bin/bash
${CRON_SCHEDULE} . /container.env && /run.sh >> /var/log/cron.log 2>&1
EOF
crontab /tmp/job.cron
rm -f /tmp/job.cron

touch /var/log/cron.log

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Container started" >> /var/log/cron.log
/next-run.sh >> /var/log/cron.log

cron
tail -f /var/log/cron.log
