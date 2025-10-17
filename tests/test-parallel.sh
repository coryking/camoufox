#!/bin/bash
# Quick parallel test runner with sensible defaults

set -e

WORKERS="${WORKERS:-auto}"
TESTS_DIR="${1:-async/}"

echo "=== Camoufox Parallel Test Runner ==="
echo "Workers: $WORKERS"
echo "Tests: $TESTS_DIR"
echo "========================================="

cd "$(dirname "$0")"

# Ensure venv exists
if [ ! -d "venv" ]; then
    echo "Setting up venv..."
    bash ./setup-venv.sh
fi

# Set executable path
EXECUTABLE_PATH="${CAMOUFOX_EXECUTABLE_PATH:-../camoufox-142.0.1-bluetaka.25/obj-x86_64-pc-linux-gnu/dist/bin/camoufox-bin}"

if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "Error: Camoufox executable not found at $EXECUTABLE_PATH"
    echo "Set CAMOUFOX_EXECUTABLE_PATH environment variable or build first"
    exit 1
fi

export CAMOUFOX_EXECUTABLE_PATH="$EXECUTABLE_PATH"

# Run with xvfb-run if available, otherwise try without
if command -v xvfb-run &> /dev/null; then
    echo "Running with Xvfb..."
    xvfb-run -a venv/bin/pytest -vv -n "$WORKERS" --headless "$TESTS_DIR" "$@"
else
    echo "Running without Xvfb (install with: sudo apt-get install xvfb)..."
    venv/bin/pytest -vv -n "$WORKERS" --headless "$TESTS_DIR" "$@"
fi