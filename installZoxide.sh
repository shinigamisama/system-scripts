#!/bin/bash

# =============================================================================
# Zoxide Installation Script
# =============================================================================
# Installs Zoxide with automatic OS detection and shell configuration
# Supports: macOS, Ubuntu/Debian, Arch Linux, Fedora/RHEL/CentOS
# Includes: Shell integration and cd alias replacement
# Author: Auto-generated script
# Date: $(date +%Y-%m-%d)
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macOS"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="linux"
        DISTRO="$ID"
    elif [[ -f /etc/redhat-release ]]; then
        OS="linux"
        DISTRO="rhel"
    else
        log_error "Unsupported operating system"
        exit 1
    fi
    
    log_info "Detected OS: $DISTRO"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect current shell
detect_shell() {
    CURRENT_SHELL=$(basename "$SHELL")
    log_info "Detected shell: $CURRENT_SHELL"
    
    case $CURRENT_SHELL in
        "zsh")
            SHELL_RC="$HOME/.zshrc"
            ;;
        "bash")
            SHELL_RC="$HOME/.bashrc"
            ;;
        *)
            log_warning "Unsupported shell: $CURRENT_SHELL"
            log_info "Defaulting to bash configuration"
            SHELL_RC="$HOME/.bashrc"
            ;;
    esac
    
    log_info "Shell configuration file: $SHELL_RC"
}

# Function to install Zoxide
install_zoxide() {
    log_header "Installing Zoxide"
    
    if command_exists zoxide; then
        log_info "Zoxide already installed: $(zoxide --version)"
        return
    fi
    
    case $DISTRO in
        "macos")
            if command_exists brew; then
                log_info "Installing Zoxide via Homebrew..."
                brew install zoxide
            else
                log_info "Installing Zoxide via curl..."
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            fi
            ;;
            
        "ubuntu"|"debian")
            # Check if zoxide is available in repos (newer versions)
            if apt-cache search zoxide | grep -q "^zoxide "; then
                log_info "Installing Zoxide via apt..."
                sudo apt update
                sudo apt install -y zoxide
            else
                log_info "Installing Zoxide via curl..."
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            fi
            ;;
            
        "arch"|"manjaro")
            log_info "Installing Zoxide via pacman..."
            sudo pacman -S --noconfirm zoxide
            ;;
            
        "fedora"|"rhel"|"centos")
            if command_exists dnf; then
                # Check if zoxide is available
                if dnf search zoxide | grep -q "zoxide"; then
                    log_info "Installing Zoxide via dnf..."
                    sudo dnf install -y zoxide
                else
                    log_info "Installing Zoxide via curl..."
                    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
                fi
            else
                log_info "Installing Zoxide via curl..."
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            fi
            ;;
            
        *)
            log_info "Installing Zoxide via curl..."
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            ;;
    esac
    
    # Ensure zoxide is in PATH
    if ! command_exists zoxide; then
        # Add ~/.local/bin to PATH if it exists
        if [[ -f "$HOME/.local/bin/zoxide" ]]; then
            export PATH="$HOME/.local/bin:$PATH"
            log_info "Added ~/.local/bin to PATH for this session"
        fi
    fi
    
    if command_exists zoxide; then
        log_success "Zoxide installed successfully: $(zoxide --version)"
    else
        log_error "Zoxide installation failed"
        exit 1
    fi
}

# Function to configure shell
configure_shell() {
    log_header "Configuring Shell Integration"
    
    # Create shell config file if it doesn't exist
    if [[ ! -f "$SHELL_RC" ]]; then
        touch "$SHELL_RC"
        log_info "Created $SHELL_RC"
    fi
    
    # Check if zoxide is already configured
    if grep -q "zoxide init" "$SHELL_RC"; then
        log_info "Zoxide already configured in $SHELL_RC"
    else
        # Add zoxide configuration
        echo "" >> "$SHELL_RC"
        echo "# Zoxide (better cd)" >> "$SHELL_RC"
        echo 'eval "$(zoxide init '"$CURRENT_SHELL"')"' >> "$SHELL_RC"
        log_success "Zoxide initialization added to $SHELL_RC"
    fi
    
    # Add ~/.local/bin to PATH if zoxide was installed there
    if [[ -f "$HOME/.local/bin/zoxide" ]]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC"; then
            echo "" >> "$SHELL_RC"
            echo "# Add ~/.local/bin to PATH" >> "$SHELL_RC"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
            log_success "Added ~/.local/bin to PATH in $SHELL_RC"
        fi
    fi
    
    # Add cd alias to replace cd with z
    if ! grep -q 'alias cd="z"' "$SHELL_RC"; then
        echo "" >> "$SHELL_RC"
        echo "# Replace cd with zoxide" >> "$SHELL_RC"
        echo 'alias cd="z"' >> "$SHELL_RC"
        log_success "Added cd alias to use zoxide in $SHELL_RC"
    else
        log_info "cd alias already configured in $SHELL_RC"
    fi
}

# Function to verify installation
verify_installation() {
    log_header "Verifying Installation"
    
    # Check if Zoxide is installed
    if command_exists zoxide; then
        ZOXIDE_VERSION=$(zoxide --version)
        log_success "Zoxide installed: $ZOXIDE_VERSION"
    else
        log_error "Zoxide not found!"
        return 1
    fi
    
    # Check shell configuration
    if [[ -f "$SHELL_RC" ]] && grep -q "zoxide init" "$SHELL_RC"; then
        log_success "Zoxide initialization configured in $SHELL_RC"
    else
        log_warning "Zoxide initialization not found in $SHELL_RC"
    fi
    
    # Check cd alias
    if [[ -f "$SHELL_RC" ]] && grep -q 'alias cd="z"' "$SHELL_RC"; then
        log_success "cd alias configured in $SHELL_RC"
    else
        log_warning "cd alias not found in $SHELL_RC"
    fi
}

# Function to show completion message
show_completion_message() {
    log_header "Installation Complete!"
    
    echo -e "${GREEN}"
    cat << 'EOF'
    ███████╗ ██████╗ ██╗  ██╗██╗██████╗ ███████╗
    ╚══███╔╝██╔═══██╗╚██╗██╔╝██║██╔══██╗██╔════╝
      ███╔╝ ██║   ██║ ╚███╔╝ ██║██║  ██║█████╗  
     ███╔╝  ██║   ██║ ██╔██╗ ██║██║  ██║██╔══╝  
    ███████╗╚██████╔╝██╔╝ ██╗██║██████╔╝███████╗
    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝ ╚══════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}🚀 Zoxide has been successfully installed!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  ${BLUE}1.${NC} Restart your terminal or run: ${GREEN}source $SHELL_RC${NC}"
    echo -e "  ${BLUE}2.${NC} Start using ${GREEN}cd${NC} (now aliased to ${GREEN}z${NC}) to navigate"
    echo -e "  ${BLUE}3.${NC} Visit some directories to build the database"
    echo ""
    echo -e "${YELLOW}How to use:${NC}"
    echo -e "  ${GREEN}cd /path/to/directory${NC}  - Navigate and learn (same as before)"
    echo -e "  ${GREEN}cd partial-name${NC}       - Jump to directory by partial match"
    echo -e "  ${GREEN}z directory${NC}           - Alternative syntax (works the same)"
    echo -e "  ${GREEN}zi${NC}                    - Interactive directory selection"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  After visiting /home/user/Documents/Projects/"
    echo -e "  You can type: ${GREEN}cd proj${NC} and it will take you there!"
    echo ""
    echo -e "${CYAN}Happy fast navigation! ⚡${NC}"
}

# Main function
main() {
    log_header "Zoxide Installation Script"
    
    echo -e "${CYAN}This script will install Zoxide (better cd) with shell integration${NC}"
    echo -e "${YELLOW}Press Enter to continue or Ctrl+C to cancel...${NC}"
    read -r
    
    detect_os
    detect_shell
    install_zoxide
    configure_shell
    verify_installation
    show_completion_message
}

# Handle script interruption
trap 'log_error "Installation interrupted"; exit 1' INT TERM

# Check if running as root (not recommended)
if [[ $EUID -eq 0 ]]; then
    log_warning "Running as root is not recommended for this installation"
    log_warning "Some features may not work correctly"
fi

# Run main function
main "$@"