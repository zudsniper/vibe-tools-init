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
CURSOR_TOOLS_INSTALL_DIR="$HOME"
REPO_URL="https://github.com/zudsniper/vibe-tools-init"
CURSOR_TOOLS_REPO="https://github.com/eastlondoner/cursor-tools"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -ni|--non-interactive)
      INTERACTIVE=false
      shift
      ;;
    -d|--dir)
      if [[ -n "$2" && "$2" != -* ]]; then
        CURSOR_TOOLS_INSTALL_DIR="$2"
        shift 2
      else
        echo -e "${RED}${BOLD}ERROR:${RESET} Argument for $1 is missing"
        exit 1
      fi
      ;;
    *)
      echo -e "${RED}${BOLD}ERROR:${RESET} Unknown option: $1"
      echo -e "Usage: install.sh [-ni|--non-interactive] [-d|--dir <path>]"
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

# Warn about installing to current directory in interactive mode
if [ "$INTERACTIVE" = true ]; then
  warning "This script will install files to your current directory."
  if ! ask "Continue installation to $(pwd)? [Y/n]" "y"; then
    echo -e "${YELLOW}Installation canceled.${RESET}"
    exit 0
  fi
fi

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

# Check if we're already in the cloned repository
if [ -f "./vibe-tools-init" ]; then
  info "Using vibe-tools-init from current directory."
else
  # Clone the repository to current directory
  info "Cloning repository from ${CYAN}$REPO_URL${RESET} to current directory..."
  git clone "$REPO_URL" . || error "Failed to clone repository to current directory"
fi

# Copy the script to installation directory
cp "./vibe-tools-init" "$INSTALL_DIR/" || error "Failed to copy vibe-tools-init"
chmod +x "$INSTALL_DIR/vibe-tools-init" || error "Failed to make vibe-tools-init executable"

# Create symbolic link for cursor-tools-init
ln -sf "$INSTALL_DIR/vibe-tools-init" "$INSTALL_DIR/cursor-tools-init" || error "Failed to create cursor-tools-init symlink"

success "Installed ${CYAN}vibe-tools-init${RESET} and ${CYAN}cursor-tools-init${RESET} to ${CYAN}$INSTALL_DIR${RESET}"

# Check if cursor-tools is available
if ! command -v cursor-tools &> /dev/null; then
  warning "cursor-tools CLI not found in PATH"
  
  if ask "Would you like to install cursor-tools? [y/N]" "n"; then
    # Prompt for installation directory if in interactive mode
    if [ "$INTERACTIVE" = true ]; then
      echo -en "${CYAN}${BOLD}Enter installation directory [${CURSOR_TOOLS_INSTALL_DIR}]: ${RESET}"
      read -r input_dir
      if [[ -n "$input_dir" ]]; then
        CURSOR_TOOLS_INSTALL_DIR="$input_dir"
      fi
    fi
    
    # Ensure installation directory is not under /tmp
    if [[ "$CURSOR_TOOLS_INSTALL_DIR" == /tmp* ]]; then
      error "Cannot install cursor-tools to a directory under /tmp"
    fi
    
    # Expand tilde in path if present
    if [[ "$CURSOR_TOOLS_INSTALL_DIR" == "~"* ]]; then
      CURSOR_TOOLS_INSTALL_DIR="${CURSOR_TOOLS_INSTALL_DIR/#\~/$HOME}"
    fi
    
    info "Installing cursor-tools from ${CYAN}$CURSOR_TOOLS_REPO${RESET} to ${CYAN}$CURSOR_TOOLS_INSTALL_DIR${RESET}..."
    
    # Create a subdirectory for cursor-tools
    mkdir -p "./cursor-tools-temp" || error "Failed to create temporary cursor-tools directory"
    
    # Create installation directory if it doesn't exist
    mkdir -p "$CURSOR_TOOLS_INSTALL_DIR" || error "Failed to create cursor-tools installation directory: $CURSOR_TOOLS_INSTALL_DIR"
    
    # Clone cursor-tools repository
    git clone "$CURSOR_TOOLS_REPO" "./cursor-tools-temp" || error "Failed to clone cursor-tools repository"
    
    # Build and install cursor-tools
    cd "./cursor-tools-temp" || error "Failed to navigate to cursor-tools directory"
    
    # Print Node.js information
    NODE_PATH=$(which node)
    NODE_VERSION=$(node -v)
    info "Using Node.js: ${CYAN}$NODE_PATH${RESET} (${CYAN}$NODE_VERSION${RESET})"
    
    npm install || error "Failed to install cursor-tools dependencies"
    npm run build || error "Failed to build cursor-tools"
    npm install -g . --prefix "$CURSOR_TOOLS_INSTALL_DIR" || error "Failed to install cursor-tools to $CURSOR_TOOLS_INSTALL_DIR"
    
    # Update PATH temporarily for version check
    export PATH="$CURSOR_TOOLS_INSTALL_DIR/bin:$PATH"
    CURSOR_TOOLS_VERSION=$(cursor-tools --version 2>/dev/null || echo "unknown")
    
    echo -e "\n${BOLD}${GREEN}cursor-tools (${CURSOR_TOOLS_VERSION}) installed to ${CYAN}$CURSOR_TOOLS_INSTALL_DIR/bin${RESET}.${RESET} ${CYAN}${CURSOR_TOOLS_REPO}${RESET}"
    echo -e "${BOLD}---${RESET}"
    
    # Add cursor-tools bin to PATH if not already there
    if [[ ":$PATH:" != *":$CURSOR_TOOLS_INSTALL_DIR/bin:"* ]]; then
      info "Adding ${CYAN}$CURSOR_TOOLS_INSTALL_DIR/bin${RESET} to PATH in shell configuration"
      
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
        echo "export PATH=\"\$PATH:$CURSOR_TOOLS_INSTALL_DIR/bin\"" >> "$SHELL_CONFIG"
        info "Updated ${CYAN}$SHELL_CONFIG${RESET}. You'll need to restart your shell or run:"
        echo -e "    ${MAGENTA}source $SHELL_CONFIG${RESET}"
      else
        warning "Could not determine shell configuration file. Please manually add:"
        echo -e "    ${MAGENTA}export PATH=\"\$PATH:$CURSOR_TOOLS_INSTALL_DIR/bin\"${RESET}"
        echo -e "to your shell configuration file."
      fi
    fi
    
    echo -e "  to set up a project, navigate to the project working directory and execute '${MAGENTA}cursor-tools install .${RESET}'"
  else
    info "Skipping cursor-tools installation"
    # Clean up cursor-tools temp directory
    cd .. && rm -rf "./cursor-tools-temp"
  fi
fi

echo -e "\n${BOLD}${GREEN}🎉 Installation Complete!${RESET}"
echo -e "You can now use ${CYAN}vibe-tools-init${RESET} or ${CYAN}cursor-tools-init${RESET} to initialize projects"
echo -e "Run ${CYAN}vibe-tools-init --help${RESET} for usage information\n"
