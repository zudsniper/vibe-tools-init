#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Default values
INTERACTIVE=true
INSTALL_DIR="$HOME/.local/bin"
REPO_URL="https://github.com/zudsniper/vibe-tools-init"
CURSOR_TOOLS_REPO="https://github.com/eastlondoner/cursor-tools"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -ni|--non-interactive)
      INTERACTIVE=false
      shift
      ;;
    *)
      echo -e "${RED}${BOLD}ERROR:${RESET} Unknown option: $1"
      echo -e "Usage: install.sh [-ni|--non-interactive]"
      exit 1
      ;;
  esac
done

print_header() {
  echo -e "\n${BOLD}${CYAN}===================================================${RESET}"
  echo -e "${BOLD}${MAGENTA}  vibe-tools-init Installer ${RESET}🚀"
  echo -e "${BOLD}${CYAN}===================================================${RESET}\n"
}

success() {
  echo -e "${GREEN}${BOLD}✅ SUCCESS:${RESET} $1"
}

info() {
  echo -e "${BLUE}${BOLD}ℹ️ INFO:${RESET} $1"
}

warning() {
  echo -e "${YELLOW}${BOLD}⚠️ WARNING:${RESET} $1" >&2
}

error() {
  echo -e "${RED}${BOLD}❌ ERROR:${RESET} $1" >&2
  exit 1
}

ask() {
  local prompt="$1"
  local default="$2"
  
  if [ "$INTERACTIVE" = false ]; then
    if [ "$default" = "y" ]; then
      return 0
    else
      return 1
    fi
  fi
  
  local yn
  while true; do
    echo -en "${CYAN}${BOLD}$prompt${RESET} "
    read -r yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      "" ) 
        if [ "$default" = "y" ]; then
          return 0
        else
          return 1
        fi
        ;;
      * ) echo -e "${YELLOW}Please answer yes or no.${RESET}";;
    esac
  done
}

# Print the header
print_header

# Create temp directory and clean it on exit
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create installation directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
  info "Creating installation directory: ${CYAN}$INSTALL_DIR${RESET}"
  mkdir -p "$INSTALL_DIR" || error "Failed to create installation directory"
fi

# Add installation directory to PATH if not already there
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  info "Adding ${CYAN}$INSTALL_DIR${RESET} to PATH in shell configuration"
  
  # Determine shell configuration file
  SHELL_CONFIG=""
  if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      SHELL_CONFIG="$HOME/.bash_profile"
    fi
  elif [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
  fi
  
  if [ -n "$SHELL_CONFIG" ]; then
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_CONFIG"
    info "Updated ${CYAN}$SHELL_CONFIG${RESET}. You'll need to restart your shell or run:"
    echo -e "    ${MAGENTA}source $SHELL_CONFIG${RESET}"
  else
    warning "Could not determine shell configuration file. Please manually add:"
    echo -e "    ${MAGENTA}export PATH=\"\$PATH:$INSTALL_DIR\"${RESET}"
    echo -e "to your shell configuration file."
  fi
fi

# Clone the repository
info "Cloning repository from ${CYAN}$REPO_URL${RESET}..."
git clone "$REPO_URL" "$TEMP_DIR/vibe-tools-init" || error "Failed to clone repository"

# Copy the script to installation directory
cp "$TEMP_DIR/vibe-tools-init/vibe-tools-init" "$INSTALL_DIR/" || error "Failed to copy vibe-tools-init"
chmod +x "$INSTALL_DIR/vibe-tools-init" || error "Failed to make vibe-tools-init executable"

# Create symbolic link for cursor-tools-init
ln -sf "$INSTALL_DIR/vibe-tools-init" "$INSTALL_DIR/cursor-tools-init" || error "Failed to create cursor-tools-init symlink"

success "Installed ${CYAN}vibe-tools-init${RESET} and ${CYAN}cursor-tools-init${RESET} to ${CYAN}$INSTALL_DIR${RESET}"

# Check if cursor-tools is available
if ! command -v cursor-tools &> /dev/null; then
  warning "cursor-tools CLI not found in PATH"
  
  if ask "Would you like to install cursor-tools? [y/N]" "n"; then
    info "Installing cursor-tools from ${CYAN}$CURSOR_TOOLS_REPO${RESET}..."
    
    # Clone cursor-tools repository
    git clone "$CURSOR_TOOLS_REPO" "$TEMP_DIR/cursor-tools" || error "Failed to clone cursor-tools repository"
    
    # Build and install cursor-tools
    cd "$TEMP_DIR/cursor-tools" || error "Failed to navigate to cursor-tools directory"
    
    # Print Node.js information
    NODE_PATH=$(which node)
    NODE_VERSION=$(node -v)
    info "Using Node.js: ${CYAN}$NODE_PATH${RESET} (${CYAN}$NODE_VERSION${RESET})"
    
    npm install || error "Failed to install cursor-tools dependencies"
    npm run build || error "Failed to build cursor-tools"
    npm install -g . || error "Failed to globally install cursor-tools"
    
    CURSOR_TOOLS_VERSION=$(cursor-tools --version 2>/dev/null || echo "unknown")
    
    echo -e "\n${BOLD}${GREEN}cursor-tools (${CURSOR_TOOLS_VERSION}) installed.${RESET} ${CYAN}${CURSOR_TOOLS_REPO}${RESET}"
    echo -e "${BOLD}---${RESET}"
    echo -e "  to set up a project, navigate to the project working directory and execute '${MAGENTA}cursor-tools install .${RESET}'"
  else
    info "Skipping cursor-tools installation"
  fi
fi

echo -e "\n${BOLD}${GREEN}🎉 Installation Complete!${RESET}"
echo -e "You can now use ${CYAN}vibe-tools-init${RESET} or ${CYAN}cursor-tools-init${RESET} to initialize projects"
echo -e "Run ${CYAN}vibe-tools-init --help${RESET} for usage information\n"
