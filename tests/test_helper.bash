#!/usr/bin/env bash

# Test helper functions for BATS tests

# Load the core functions
load "${BATS_TEST_DIRNAME}/../lib/core/dotfiles_core.sh"

# Setup function to run before each test
setup() {
  # Create a temporary directory for testing
  TEST_TEMP_DIR=$(mktemp -d)
  
  # Set up test directories
  export TEST_SOURCE_DIR="${TEST_TEMP_DIR}/source"
  export TEST_TARGET_DIR="${TEST_TEMP_DIR}/target"
  export TEST_TRACKED_FILES="${TEST_TEMP_DIR}/tracked_files.conf"
  
  # Create test directories
  mkdir -p "${TEST_SOURCE_DIR}/.config/test-app"
  mkdir -p "${TEST_TARGET_DIR}"
  
  # Create test files
  echo "ENV=test" > "${TEST_SOURCE_DIR}/.testrc"
  echo '{"app": "test-app", "version": "1.0"}' > "${TEST_SOURCE_DIR}/.config/test-app/config.json"
  
  # Create tracked files list
  cat > "${TEST_TRACKED_FILES}" << EOF
.testrc:.testrc
.config/test-app/config.json:.config/test-app/config.json
EOF
}

# Teardown function to run after each test
teardown() {
  # Clean up the temporary directory
  if [ -d "${TEST_TEMP_DIR}" ]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

# Helper function to create test files
create_test_file() {
  local file_path="$1"
  local content="${2:-}"
  
  # Create parent directory if it doesn't exist
  mkdir -p "$(dirname "${TEST_SOURCE_DIR}/${file_path}")"
  
  # Create the file with content
  echo -e "${content}" > "${TEST_SOURCE_DIR}/${file_path}"
  
  # Add to tracked files if not already there
  if ! grep -q "^${file_path}:" "${TEST_TRACKED_FILES}"; then
    echo "${file_path}:${file_path}" >> "${TEST_TRACKED_FILES}"
  fi
}

# Helper function to verify file was installed
assert_file_installed() {
  local source_file="$1"
  local target_file="${TEST_TARGET_DIR}/$2"
  
  [ -f "${target_file}" ] || return 1
  
  if [ -n "${3:-}" ]; then
    # Verify content if provided
    [ "$(cat "${target_file}")" = "${3}" ] || return 1
  fi
  
  return 0
}

# Helper function to run install_dotfiles with test parameters
run_install() {
  local source_dir="${1:-${TEST_SOURCE_DIR}}"
  local target_dir="${2:-${TEST_TARGET_DIR}}"
  local tracked_files="${3:-${TEST_TRACKED_FILES}}"
  
  run install_dotfiles "${source_dir}" "${target_dir}" "${tracked_files}"
  echo "$output"
  return $status
}
