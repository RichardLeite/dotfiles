#!/usr/bin/env bash

# Exit on error
set -e

# Check if bats is installed
if ! command -v bats &> /dev/null; then
  echo "Error: bats is required to run tests. Please install it first."
  echo "On Ubuntu/Debian: sudo apt install bats"
  echo "On macOS: brew install bats"
  exit 1
fi

# Get the directory where this script is located
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run all unit tests
echo "Running unit tests..."
if ! bats "${TEST_DIR}/unit"; then
  echo "❌ Some unit tests failed"
  exit 1
fi

echo "✅ All tests passed successfully!"
