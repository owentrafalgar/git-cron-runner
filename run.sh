#!/bin/bash
set -uo pipefail

REPO_DIR="/repo"
GIT_HOST="${GIT_HOST:-github.com}"
SCRIPT_PATH="${SCRIPT_PATH:-run.sh}"
SCRIPT_WORKDIR="${SCRIPT_WORKDIR:-.}"
COMMIT_PATHS="${COMMIT_PATHS:-.}"
STATUS_DIR="/status"
STATUS_FILE="$STATUS_DIR/status.status"
JOB_NAME="${JOB_NAME:-job}"

mkdir -p "$STATUS_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${JOB_NAME}: $*"
}

write_status() {
    echo "TIMESTAMP=$(date +%s)" > "$STATUS_FILE"
    echo "EXIT_CODE=$1" >> "$STATUS_FILE"
}

log "starting"

EXIT_CODE=0
RESULT_MSG=""

# Fail early (with a status file for monitoring) if required variables are missing
MISSING=""
for var in GIT_USER GIT_REPO GIT_TOKEN; do
    [ -n "${!var:-}" ] || MISSING="$MISSING $var"
done
if [ -n "$MISSING" ]; then
    EXIT_CODE=1
    RESULT_MSG="missing required variable(s):$MISSING"
fi

# The URL contains no credentials; the token is supplied at runtime by a
# credential helper that reads GIT_USER/GIT_TOKEN from the environment.
# This keeps the token out of /repo/.git/config and picks up token changes.
REPO_URL="https://${GIT_HOST}/${GIT_USER:-}/${GIT_REPO:-}.git"

if [ "$EXIT_CODE" -eq 0 ]; then
    git config --global user.email "${GIT_EMAIL:-automation@localhost}"
    git config --global user.name "${GIT_NAME:-Automation Bot}"
    git config --global safe.directory "$REPO_DIR"
    git config --global credential.helper \
        '!f() { test "$1" = get && echo "username=$GIT_USER" && echo "password=$GIT_TOKEN"; }; f'

    if [ ! -d "$REPO_DIR/.git" ]; then
        if ! git clone --quiet "$REPO_URL" "$REPO_DIR"; then
            EXIT_CODE=1
            RESULT_MSG="git clone failed"
        fi
    else
        cd "$REPO_DIR"
        # Overwrite the remote URL on every run (also removes tokens from older clones).
        # Hard-reset to the remote state so leftovers from failed runs (unpushed commits,
        # half-modified files) can never block or pollute later runs.
        if ! { git remote set-url origin "$REPO_URL" && \
               git fetch --quiet origin && \
               git reset --quiet --hard '@{u}' && \
               git clean --quiet -fd; }; then
            EXIT_CODE=1
            RESULT_MSG="git fetch/reset failed"
        fi
    fi
fi

if [ "$EXIT_CODE" -eq 0 ]; then
    if ! cd "$REPO_DIR/$SCRIPT_WORKDIR"; then
        EXIT_CODE=1
        RESULT_MSG="SCRIPT_WORKDIR '$SCRIPT_WORKDIR' not found"
    elif bash "$SCRIPT_PATH"; then
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

write_status "$EXIT_CODE"

if [ "$EXIT_CODE" -ne 0 ]; then
    log "FAILED - $RESULT_MSG"
else
    log "success - $RESULT_MSG"
fi

log "finished"

/next-run.sh

exit "$EXIT_CODE"
