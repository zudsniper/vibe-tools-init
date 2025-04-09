#!/bin/bash

# install-all.sh - A wrapper for install.sh that defaults to installing cursor-tools
# This script performs the same installation as install.sh but changes the default answer
# for "Would you like to install cursor-tools?" from No to Yes, and installs cursor-tools
# to the user's home directory by default.

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Print a small banner explaining what this script does
echo -e "\n${BOLD}${CYAN}===================================================${RESET}"
echo -e "${BOLD}${MAGENTA}  vibe-tools-init Complete Installer ${RESET}🚀"
echo -e "${BOLD}${CYAN}===================================================${RESET}\n"
echo -e "${BLUE}${BOLD}ℹ️ INFO:${RESET} This installer will automatically install both vibe-tools-init AND cursor-tools by default"
echo -e "${BLUE}${BOLD}ℹ️ INFO:${RESET} cursor-tools will be installed to your home directory unless specified with --dir"
echo -e "${BLUE}${BOLD}ℹ️ INFO:${RESET} You can still opt out of cursor-tools installation by answering 'n' at the prompt\n"

# Store the original directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
INSTALL_DIR="$HOME"
EXTRA_ARGS=()

# Parse arguments to handle --dir option and pass through other arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      if [[ -n "$2" && "$2" != -* ]]; then
        INSTALL_DIR="$2"
        shift 2
      else
        echo -e "${RED}${BOLD}ERROR:${RESET} Argument for $1 is missing"
        echo -e "Usage: install-all.sh [-ni|--non-interactive] [-d|--dir <path>]"
        exit 1
      fi
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

# This function will override the original ask() function in install.sh
# It will change the default for cursor-tools installation from "n" to "y"
override_install_sh() {
  # Create a temporary file with modified content
  temp_file=$(mktemp)
  
  # Use sed to:
  # 1. Modify the default value from "n" to "y" for cursor-tools installation prompt
  # 2. Ensure cursor-tools installs to the specified directory
  sed 's/Would you like to install cursor-tools? \[y\/N\]" "n"/Would you like to install cursor-tools? [Y\/n]" "y"/' \
      "$SCRIPT_DIR/install.sh" > "$temp_file"
  
  # Make the temporary file executable
  chmod +x "$temp_file"
  
  # Execute the modified script with the --dir flag and any other arguments
  "$temp_file" --dir "$INSTALL_DIR" "${EXTRA_ARGS[@]}"
  
  # Save the exit code
  exit_code=$?
  
  # Clean up the temporary file
  rm "$temp_file"
  
  # Return with the same exit code
  return $exit_code
}

# Call the override function and pass all arguments
override_install_sh "$@"

# Exit with the same code as the modified install.sh
exit $?

