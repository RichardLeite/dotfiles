#!/usr/bin/env bats

# Load the test helper functions
load "${BATS_TEST_DIRNAME}/../test_helper"

# Test setup function - runs before each test
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

# Test teardown function - runs after each test
teardown() {
  # Clean up the temporary directory
  rm -rf "${TEST_TEMP_DIR}"
}

@test "install_dotfiles should install files to target directory" {
  # Run the install function
  run install_dotfiles "${TEST_SOURCE_DIR}" "${TEST_TARGET_DIR}" "${TEST_TRACKED_FILES}"
  
  # Check the exit status
  [ "$status" -eq 0 ]
  
  # Check if files were installed
  [ -f "${TEST_TARGET_DIR}/.testrc" ]
  [ -f "${TEST_TARGET_DIR}/.config/test-app/config.json" ]
  
  # Check file contents
  [ "$(cat "${TEST_TARGET_DIR}/.testrc")" = "ENV=test" ]
  [ "$(jq -r '.app' "${TEST_TARGET_DIR}/.config/test-app/config.json")" = "test-app" ]
}

@test "install_dotfiles should backup existing files" {
  # Create existing file
  mkdir -p "${TEST_TARGET_DIR}/.config/test-app"
  echo "ENV=old" > "${TEST_TARGET_DIR}/.testrc"
  
  # Run the install function
  run install_dotfiles "${TEST_SOURCE_DIR}" "${TEST_TARGET_DIR}" "${TEST_TRACKED_FILES}"
  
  # Check the exit status
  [ "$status" -eq 0 ]
  
  # Check if backup was created
  local backup_file="${TEST_TARGET_DIR}/.testrc.bak.*"
  ls "${TEST_TARGET_DIR}"/.testrc.bak.* >/dev/null 2>&1
  
  # Check if file was updated
  [ "$(cat "${TEST_TARGET_DIR}/.testrc")" = "ENV=test" ]
}

@test "install_dotfiles should handle directories" {
  # Create a test directory with files
  mkdir -p "${TEST_SOURCE_DIR}/.config/test-app/plugins"
  echo "plugin1" > "${TEST_SOURCE_DIR}/.config/test-app/plugins/plugin1"
  echo "plugin2" > "${TEST_SOURCE_DIR}/.config/test-app/plugins/plugin2"
  
  # Update tracked files to include the directory
  echo ".config/test-app/plugins:.config/test-app/plugins" >> "${TEST_TRACKED_FILES}"
  
  # Run the install function
  run install_dotfiles "${TEST_SOURCE_DIR}" "${TEST_TARGET_DIR}" "${TEST_TRACKED_FILES}"
  
  # Check the exit status
  [ "$status" -eq 0 ]
  
  # Check if directory and files were installed
  [ -d "${TEST_TARGET_DIR}/.config/test-app/plugins" ]
  [ -f "${TEST_TARGET_DIR}/.config/test-app/plugins/plugin1" ]
  [ -f "${TEST_TARGET_DIR}/.config/test-app/plugins/plugin2" ]
  [ "$(cat "${TEST_TARGET_DIR}/.config/test-app/plugins/plugin1")" = "plugin1" ]
}

@test "install_dotfiles should handle missing source files" {
  # Add a non-existent file to tracked files
  echo "non-existent-file:non-existent-file" >> "${TEST_TRACKED_FILES}"
  
  # Run the install function
  run install_dotfiles "${TEST_SOURCE_DIR}" "${TEST_TARGET_DIR}" "${TEST_TRACKED_FILES}"
  
  # Check the exit status (should still succeed with warning)
  [ "$status" -eq 0 ]
  
  # Check if valid files were still installed
  [ -f "${TEST_TARGET_DIR}/.testrc" ]
  [ -f "${TEST_TARGET_DIR}/.config/test-app/config.json" ]
}

@test "install_dotfiles should handle invalid parameters" {
  # Test with missing parameters
  run install_dotfiles
  [ "$status" -ne 0 ]
  
  # Test with non-existent source directory
  run install_dotfiles "/non/existent/source" "${TEST_TARGET_DIR}" "${TEST_TRACKED_FILES}"
  [ "$status" -ne 0 ]
  
  # Test with non-existent tracked files
  run install_dotfiles "${TEST_SOURCE_DIR}" "${TEST_TARGET_DIR}" "/non/existent/tracked_files"
  [ "$status" -ne 0 ]
}
