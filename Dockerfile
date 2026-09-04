FROM debian:bookworm-slim

LABEL org.opencontainers.image.description="Generic container that clones a Git repo, runs a script on a schedule, and commits/pushes changes back."
LABEL org.opencontainers.image.source="https://github.com/owentrafalgar/git-cron-runner"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash git wget ca-certificates cron python3 python3-croniter && \
    rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
COPY next-run.sh /next-run.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /run.sh /next-run.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
