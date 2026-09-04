#!/bin/bash
set -uo pipefail

REPO_DIR="/repo"
REPO_URL="https://${GIT_USER}:${GIT_TOKEN}@${GIT_HOST}/${GIT_USER}/${GIT_REPO}.git"
SCRIPT_PATH="${SCRIPT_PATH:-run.sh}"
SCRIPT_WORKDIR="${SCRIPT_WORKDIR:-.}"
COMMIT_PATHS="${COMMIT_PATHS:-.}"
STATUS_DIR="/status"
STATUS_FILE="$STATUS_DIR/status.status"
JOB_NAME="${JOB_NAME:-job}"

mkdir -p "$STATUS_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${JOB_NAME}: starting"

EXIT_CODE=0
RESULT_MSG=""

if [ ! -d "$REPO_DIR/.git" ]; then
    git clone --quiet "$REPO_URL" "$REPO_DIR" || EXIT_CODE=$?
else
    cd "$REPO_DIR"
    git pull --quiet || EXIT_CODE=$?
fi

if [ "$EXIT_CODE" -eq 0 ]; then
    git config --global user.email "${GIT_EMAIL:-automation@localhost}"
    git config --global user.name "${GIT_NAME:-Automation Bot}"
    git config --global --add safe.directory "$REPO_DIR"

    cd "$REPO_DIR/$SCRIPT_WORKDIR"
    if bash "$SCRIPT_PATH"; then
        cd "$REPO_DIR"
        if [ -n "$(git status --porcelain -- $COMMIT_PATHS)" ]; then
            if git add $COMMIT_PATHS && \
               git commit --quiet -m "Auto-update ($(date +%Y-%m-%d))" && \
               git push --quiet; then
                RESULT_MSG="changes pushed"
            else
                EXIT_CODE=1
                RESULT_MSG="git commit/push failed"
            fi
        else
            RESULT_MSG="no changes"
        fi
    else
        EXIT_CODE=$?
        RESULT_MSG="$SCRIPT_PATH failed"
    fi
fi

echo "TIMESTAMP=$(date +%s)" > "$STATUS_FILE"
echo "EXIT_CODE=$EXIT_CODE" >> "$STATUS_FILE"

if [ "$EXIT_CODE" -ne 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${JOB_NAME}: FAILED - $RESULT_MSG"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${JOB_NAME}: success - $RESULT_MSG"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${JOB_NAME}: finished"

/next-run.sh

exit "$EXIT_CODE"
