# syntax=docker/dockerfile:1

# Stage 1: Fetch latest upstream source
FROM alpine/git:latest AS fetcher
ARG GIT_REPO="https://github.com/televisualarts-cloud/grid-monitor.git"
ARG GIT_BRANCH="main"
# Pass --build-arg CACHEBUST=$(date +%s) or run with --no-cache to pull latest commits
ARG CACHEBUST=1
WORKDIR /src
RUN git clone --depth 1 --branch "${GIT_BRANCH}" "${GIT_REPO}" . \
    || git clone --depth 1 "${GIT_REPO}" .

# Stage 2: Minimal runtime image
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8412 \
    TZ=Europe/London

# Create non-root user and group
RUN groupadd -g 1000 gridmon \
    && useradd -u 1000 -g gridmon -s /sbin/nologin -M gridmon \
    && mkdir -p /opt/grid-monitor /data \
    && chown -R gridmon:gridmon /opt/grid-monitor /data

# Copy upstream application files from fetcher stage
COPY --from=fetcher --chown=gridmon:gridmon /src/ /opt/grid-monitor/
COPY --chown=gridmon:gridmon entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER gridmon
WORKDIR /data

EXPOSE 8412

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python3 -c "import urllib.request, os; urllib.request.urlopen(f'http://127.0.0.1:{os.environ.get(\"PORT\", 8412)}')" || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]