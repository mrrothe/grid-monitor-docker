#!/usr/bin/env bash
set -euo pipefail

APP_SRC="/opt/grid-monitor"
DATA_DIR="/data"

# Copy latest code and static assets into the persistent working directory
# without overwriting existing user config or historical JSON data.
cp -f "${APP_SRC}"/*.py "${DATA_DIR}/" 2>/dev/null || true
cp -f "${APP_SRC}"/*.html "${DATA_DIR}/" 2>/dev/null || true

if [ -f "${APP_SRC}/region_polys.json" ]; then
    cp -f "${APP_SRC}/region_polys.json" "${DATA_DIR}/"
fi

# Ensure the Python HTTP server binds to all interfaces (0.0.0.0) inside the container
sed -i 's/("127\.0\.0\.1",/("0.0.0.0",/g; s/("localhost",/("0.0.0.0",/g' "${DATA_DIR}/grid_server.py"
sed -i "s/('127\.0\.0\.1',/('0.0.0.0',/g; s/('localhost',/('0.0.0.0',/g" "${DATA_DIR}/grid_server.py"

cd "${DATA_DIR}"
exec python3 -u grid_server.py --port "${PORT:-8412}" "$@"