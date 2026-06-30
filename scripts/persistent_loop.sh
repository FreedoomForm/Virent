#!/bin/bash
# Persistent infinite loop — restarts itself if it stops
# Run with: nohup bash scripts/persistent_loop.sh > /tmp/persistent_loop.log 2>&1 &

cd /home/z/my-project

while true; do
    echo "[$(date)] === Starting infinite_loop.py ==="
    python3 scripts/infinite_loop.py
    EXIT_CODE=$?
    echo "[$(date)] infinite_loop.py exited with code $EXIT_CODE"
    echo "[$(date)] Restarting in 5 seconds..."
    sleep 5
done
