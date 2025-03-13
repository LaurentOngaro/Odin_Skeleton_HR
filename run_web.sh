#!/bin/bash

# This script starts a simple HTTP server to serve the contents of the build/web directory.

OUT_DIR="build/web"

if [ ! -d "$OUT_DIR" ]; then
  echo "Error: Directory '$OUT_DIR' does not exist."
  exit 1
fi

cd "$OUT_DIR" || exit

# Launch the server in the background
python3 -m http.server 8000 &
echo "Server started at http://localhost:8000"

# Open the default browser
xdg-open http://localhost:8000
