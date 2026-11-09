#!/bin/bash
# Starts the dev server, renders / on the server 5 times, takes a heap snapshot (which forces a full GC), renders it
# 20 more times, and takes another. Prints both snapshot sizes. Needs curl and Node 22.
set -e
PORT=${PORT:-8299}
rm -f ./*.heapsnapshot
BROWSER=none NODE_OPTIONS="--heapsnapshot-signal=SIGUSR2" npx expo start --web --port "$PORT" > metro.log 2>&1 &
until curl -sf -o /dev/null "http://localhost:$PORT/"; do sleep 2; done
PID=$(pgrep -f "node .*expo start --web --port $PORT" | head -1)
snapshot() {
  kill -USR2 "$PID"
  until ls ./*.heapsnapshot >/dev/null 2>&1; do sleep 1; done
  local f prev=-1; f=$(ls ./*.heapsnapshot)
  until [ "$(stat -c %s "$f")" = "$prev" ] && [ "$prev" != 0 ]; do prev=$(stat -c %s "$f"); sleep 3; done
  echo "$((prev / 1048576)) MB"; rm -f "$f"
}
for i in $(seq 1 5); do curl -s -o /dev/null "http://localhost:$PORT/"; done
echo "heap snapshot after 5 requests:  $(snapshot)"
for i in $(seq 1 20); do curl -s -o /dev/null "http://localhost:$PORT/"; done
echo "heap snapshot after 25 requests: $(snapshot)"
kill "$PID"
