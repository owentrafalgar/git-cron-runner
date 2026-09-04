FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash git wget ca-certificates cron python3 python3-croniter && \
    rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
COPY next-run.sh /next-run.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /run.sh /next-run.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
