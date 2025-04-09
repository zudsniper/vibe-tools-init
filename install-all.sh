#!/bin/bash

# install-all.sh - A wrapper for install.sh that installs vibe-tools-init and cursor-tools
# This script performs a non-interactive installation of both vibe-tools-init 
# (using the standard install.sh) and cursor-tools (using npm install -g)

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
echo -e "${BOLD}${MAGENTA}  vibe-tools-init + cursor-tools Installer ${RESET}🚀"
echo -e "${BOLD}${CYAN}===================================================${RESET}\n"
echo -e "${BLUE}${BOLD}ℹ️ INFO:${RESET} This installer will:"
echo -e "${BLUE}${BOLD}  1.${RESET} Install vibe-tools-init (can be temporary or permanent)"
echo -e "${BLUE}${BOLD}  2.${RESET} Clone and install cursor-tools to your directory of choice"
echo -e "${BLUE}${BOLD}ℹ️ INFO:${RESET} No prompts will be shown - this is a fully automated installation\n"

# Store the original directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
EXTRA_ARGS=()
INSTALL_DIR="$HOME"

# Parse arguments to handle --dir option and pass through other arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      if [[ -n "$2" && "$2" != -* ]]; then
        INSTALL_DIR="$2"
        shift 2
      else
        echo -e "${RED}${BOLD}ERROR:${RESET} Argument for $1 is missing"
        echo -e "Usage: install-all.sh [-d|--dir <path>]"
        exit 1
      fi
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

# Expand tilde in installation directory path if present
if [[ "$INSTALL_DIR" == "~"* ]]; then
  INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
fi

# Ensure the installation directory is a valid path
if [[ "$INSTALL_DIR" == /tmp/* ]]; then
  echo -e "${YELLOW}${BOLD}⚠️ Warning:${RESET} Installing cursor-tools to /tmp/ is not recommended."
  echo -e "${YELLOW}${BOLD}⚠️ Warning:${RESET} Using home directory instead."
  INSTALL_DIR="$HOME"
fi

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Install vibe-tools-init using the standard installer
install_vibe_tools_init() {
  echo -e "\n${CYAN}${BOLD}➡️ Installing vibe-tools-init...${RESET}"
  
  # Run the install.sh script with --non-interactive flag and any other provided arguments
  "$SCRIPT_DIR/install.sh" --non-interactive "${EXTRA_ARGS[@]}"
  
  # Save the exit code
  local exit_code=$?
  
  if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ vibe-tools-init installation completed successfully${RESET}"
  else
    echo -e "${RED}${BOLD}❌ vibe-tools-init installation failed (exit code: $exit_code)${RESET}"
    return $exit_code
  fi
  
  return 0
}

# Install cursor-tools by cloning the repository
install_cursor_tools() {
  echo -e "\n${CYAN}${BOLD}➡️ Installing cursor-tools to ${INSTALL_DIR}...${RESET}"
  
  # Check if git is installed
  if ! command_exists git; then
    echo -e "${RED}${BOLD}❌ git is not installed. Please install git first.${RESET}"
    return 1
  fi
  
  # Create installation directory if it doesn't exist
  if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
      echo -e "${RED}${BOLD}❌ Failed to create installation directory: $INSTALL_DIR${RESET}"
      return 1
    fi
  fi
  
  # Clone cursor-tools repository
  cursor_tools_dir="$INSTALL_DIR/cursor-tools"
  
  # If directory already exists, try to pull latest changes
  if [ -d "$cursor_tools_dir" ]; then
    echo -e "${YELLOW}${BOLD}⚠️ cursor-tools directory already exists.${RESET}"
    echo -e "${CYAN}${BOLD}➡️ Updating existing installation...${RESET}"
    
    cd "$cursor_tools_dir"
    git pull origin main
    
    if [ $? -ne 0 ]; then
      echo -e "${YELLOW}${BOLD}⚠️ Unable to update existing cursor-tools repository.${RESET}"
      echo -e "${YELLOW}${BOLD}⚠️ Proceeding with existing installation.${RESET}"
    fi
  else
    # Clone the repository
    git clone https://github.com/cursor-ai/cursor-tools.git "$cursor_tools_dir"
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}${BOLD}❌ Failed to clone cursor-tools repository.${RESET}"
      return 1
    fi
    
    cd "$cursor_tools_dir"
  fi
  
  # Install dependencies if package.json exists
  if [ -f "package.json" ]; then
    echo -e "${CYAN}${BOLD}➡️ Installing cursor-tools dependencies...${RESET}"
    
    # Check if npm is installed
    if ! command_exists npm; then
      echo -e "${RED}${BOLD}❌ npm is not installed. Please install Node.js and npm first.${RESET}"
      return 1
    fi
    
    # Install dependencies
    npm install
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}${BOLD}❌ Failed to install cursor-tools dependencies.${RESET}"
      return 1
    fi
  fi
  
  # Run any setup or build scripts if available
  if [ -f "setup.sh" ]; then
    echo -e "${CYAN}${BOLD}➡️ Running cursor-tools setup script...${RESET}"
    chmod +x setup.sh
    ./setup.sh
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}${BOLD}❌ Failed to run cursor-tools setup script.${RESET}"
      return 1
    fi
  elif [ -f "build.sh" ]; then
    echo -e "${CYAN}${BOLD}➡️ Running cursor-tools build script...${RESET}"
    chmod +x build.sh
    ./build.sh
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}${BOLD}❌ Failed to run cursor-tools build script.${RESET}"
      return 1
    fi
  fi
  
  echo -e "${GREEN}${BOLD}✅ cursor-tools installed successfully to: ${cursor_tools_dir}${RESET}"
  return 0
}

# Main installation process
main() {
  # Step 1: Install vibe-tools-init
  install_vibe_tools_init
  vibe_exit_code=$?
  
  # Step 2: Install cursor-tools via npm
  if [ $vibe_exit_code -eq 0 ]; then
    install_cursor_tools
    cursor_exit_code=$?
  else
    cursor_exit_code=1
  fi
  
  # Print summary
  echo -e "\n${BOLD}${CYAN}===================================================${RESET}"
  echo -e "${BOLD}${MAGENTA}  Installation Summary ${RESET}"
  echo -e "${BOLD}${CYAN}===================================================${RESET}"
  
  if [ $vibe_exit_code -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ vibe-tools-init: Installed successfully${RESET}"
  else
    echo -e "${RED}${BOLD}❌ vibe-tools-init: Installation failed${RESET}"
  fi
  
  if [ $cursor_exit_code -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ cursor-tools: Installed to ${INSTALL_DIR}/cursor-tools${RESET}"
  else
    echo -e "${RED}${BOLD}❌ cursor-tools: Installation failed${RESET}"
  fi
  
  # Return overall status
  if [ $vibe_exit_code -eq 0 ] && [ $cursor_exit_code -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

# Run the main installation process
main
exit $?

