# git-cron-runner

Generic container: clones a Git repo, runs a script from it on a schedule, and commits/pushes
any resulting changes back. Used for automation like refreshing a generated file and keeping
it version-controlled.

## Environment variables

All configuration is done via environment variables, typically in a `stack.env` file
(see `stack.env.example`).

| Variable         | Required | Default                | Description |
|------------------|----------|-------------------------|-------------|
| GIT_HOST         | no       | github.com               | Git server hostname |
| GIT_USER         | yes      |                           | GitHub username/org |
| GIT_REPO         | yes      |                           | Repository name (without .git) |
| GIT_TOKEN        | yes      |                           | Personal access token |
| GIT_EMAIL        | no       | automation@localhost      | Commit author email |
| GIT_NAME         | no       | Automation Bot            | Commit author name |
| SCRIPT_WORKDIR   | no       | .                         | Directory (relative to repo root) to `cd` into before running the script |
| SCRIPT_PATH      | no       | run.sh                    | Script to execute, relative to SCRIPT_WORKDIR |
| COMMIT_PATHS     | no       | .                         | Path(s) (relative to repo root) to `git add` and check for changes |
| JOB_NAME         | no       | job                       | Label used in log lines |
| CRON_SCHEDULE    | no       | 0 3 * * 0 (weekly Sunday) | Standard 5-field cron syntax |
| TZ               | no       | UTC                       | Timezone for cron/log timestamps |

## Volumes

- `/repo` - persists the cloned repo between runs (avoids re-cloning every time)
- `/status` - contains `status.status` (`TIMESTAMP=...` / `EXIT_CODE=...`) for external monitoring (e.g. a Checkmk local check)

## Versioning

Every push to `main` (including automated Dependabot merges) automatically creates a new semantic
version tag (e.g. `v1.0.3`) and publishes the image under both that tag and `:latest` on GHCR.
See the repo's Releases and Packages tabs for the full history.

By default, `docker-compose.example.yml` uses `:latest`. To pin a specific version instead, set
`IMAGE_TAG` (e.g. `IMAGE_TAG=v1.0.3`) as a Compose environment variable when deploying the stack
(not inside `stack.env`, which is passed to the container itself).

## Setup

1. Copy `docker-compose.example.yml` to `docker-compose.yml` (or paste into Portainer's stack editor).
2. Copy `stack.env.example` to `stack.env` and fill in your values.
3. Deploy.

## Manual run

    docker exec my-job /run.sh
