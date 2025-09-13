#!/bin/bash

# =============================================================================
# Starship Installation Script
# =============================================================================
# Installs Starship.rs with automatic OS detection and shell configuration
# Supports: macOS, Ubuntu/Debian, Arch Linux, Fedora/RHEL/CentOS
# Includes: Catppuccin Powerline theme configuration
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

# Function to install Starship
install_starship() {
    log_header "Installing Starship"
    
    if command_exists starship; then
        log_info "Starship already installed: $(starship --version)"
        return
    fi
    
    case $DISTRO in
        "macos")
            if command_exists brew; then
                log_info "Installing Starship via Homebrew..."
                brew install starship
            else
                log_info "Installing Starship via curl..."
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            fi
            ;;
            
        "ubuntu"|"debian")
            log_info "Installing Starship via curl..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
            ;;
            
        "arch"|"manjaro")
            log_info "Installing Starship via pacman..."
            sudo pacman -S --noconfirm starship
            ;;
            
        "fedora"|"rhel"|"centos")
            if command_exists dnf; then
                log_info "Installing Starship via dnf..."
                sudo dnf install -y starship
            else
                log_info "Installing Starship via curl..."
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            fi
            ;;
            
        *)
            log_info "Installing Starship via curl..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
            ;;
    esac
    
    # Ensure starship is in PATH
    if ! command_exists starship; then
        # Add ~/.local/bin to PATH if it exists
        if [[ -f "$HOME/.local/bin/starship" ]]; then
            export PATH="$HOME/.local/bin:$PATH"
            log_info "Added ~/.local/bin to PATH for this session"
        fi
    fi
    
    if command_exists starship; then
        log_success "Starship installed successfully: $(starship --version)"
    else
        log_error "Starship installation failed"
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
    
    # Check if starship is already configured
    if grep -q "starship init" "$SHELL_RC"; then
        log_info "Starship already configured in $SHELL_RC"
        return
    fi
    
    # Add starship configuration
    echo "" >> "$SHELL_RC"
    echo "# Starship prompt" >> "$SHELL_RC"
    echo 'eval "$(starship init '"$CURRENT_SHELL"')"' >> "$SHELL_RC"
    
    # Add ~/.local/bin to PATH if starship was installed there
    if [[ -f "$HOME/.local/bin/starship" ]]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC"; then
            echo "" >> "$SHELL_RC"
            echo "# Add ~/.local/bin to PATH" >> "$SHELL_RC"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        fi
    fi
    
    log_success "Starship configuration added to $SHELL_RC"
}

# Function to install Catppuccin theme
install_catppuccin_theme() {
    log_header "Installing Catppuccin Powerline Theme"
    
    # Create config directory
    mkdir -p "$HOME/.config"
    
    # Install Catppuccin Powerline preset
    log_info "Installing Catppuccin Powerline preset..."
    if command_exists starship; then
        starship preset catppuccin-powerline -o ~/.config/starship.toml
        log_success "Catppuccin Powerline theme installed to ~/.config/starship.toml"
    else
        log_error "Starship command not found, cannot install theme"
        exit 1
    fi
    
    # Show theme info
    log_info "Theme configuration saved to: ~/.config/starship.toml"
    log_info "You can customize the theme by editing this file"
}

# Function to install fonts (optional but recommended)
install_fonts() {
    log_header "Installing Powerline Fonts"
    
    case $DISTRO in
        "macos")
            if command_exists brew; then
                log_info "Installing Nerd Fonts via Homebrew..."
                brew tap homebrew/cask-fonts
                brew install --cask font-fira-code-nerd-font font-jetbrains-mono-nerd-font
                log_success "Nerd Fonts installed"
            else
                log_warning "Homebrew not available, please install Nerd Fonts manually"
                log_info "Visit: https://www.nerdfonts.com/font-downloads"
            fi
            ;;
            
        "ubuntu"|"debian")
            log_info "Installing fonts-powerline..."
            sudo apt update
            sudo apt install -y fonts-powerline fonts-firacode
            
            # Try to install nerd fonts if available
            if sudo apt list | grep -q "fonts-nerd"; then
                sudo apt install -y fonts-nerd-font-firacode fonts-nerd-font-jetbrainsmono
            fi
            log_success "Powerline fonts installed"
            ;;
            
        "arch"|"manjaro")
            log_info "Installing powerline fonts..."
            sudo pacman -S --noconfirm powerline-fonts ttf-fira-code
            
            # Try to install nerd fonts from AUR if yay is available
            if command_exists yay; then
                yay -S --noconfirm nerd-fonts-fira-code nerd-fonts-jetbrains-mono
            fi
            log_success "Powerline fonts installed"
            ;;
            
        "fedora"|"rhel"|"centos")
            if command_exists dnf; then
                log_info "Installing powerline fonts..."
                sudo dnf install -y powerline-fonts fira-code-fonts
            fi
            log_success "Powerline fonts installed"
            ;;
            
        *)
            log_warning "Font installation not supported for this OS"
            log_info "Please install Nerd Fonts manually from: https://www.nerdfonts.com/"
            ;;
    esac
}

# Function to verify installation
verify_installation() {
    log_header "Verifying Installation"
    
    # Check if Starship is installed
    if command_exists starship; then
        STARSHIP_VERSION=$(starship --version)
        log_success "Starship installed: $STARSHIP_VERSION"
    else
        log_error "Starship not found!"
        return 1
    fi
    
    # Check if config file exists
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        log_success "Starship configuration found: ~/.config/starship.toml"
    else
        log_warning "Starship configuration not found"
    fi
    
    # Check shell configuration
    if [[ -f "$SHELL_RC" ]] && grep -q "starship init" "$SHELL_RC"; then
        log_success "Shell integration configured in $SHELL_RC"
    else
        log_warning "Shell integration not found in $SHELL_RC"
    fi
}

# Function to show completion message
show_completion_message() {
    log_header "Installation Complete!"
    
    echo -e "${GREEN}"
    cat << 'EOF'
    ███████╗████████╗ █████╗ ██████╗ ███████╗██╗  ██╗██╗██████╗ 
    ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║  ██║██║██╔══██╗
    ███████╗   ██║   ███████║██████╔╝███████╗███████║██║██████╔╝
    ╚════██║   ██║   ██╔══██║██╔══██╗╚════██║██╔══██║██║██╔═══╝ 
    ███████║   ██║   ██║  ██║██║  ██║███████║██║  ██║██║██║     
    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝     
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}🚀 Starship has been successfully installed!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  ${BLUE}1.${NC} Restart your terminal or run: ${GREEN}source $SHELL_RC${NC}"
    echo -e "  ${BLUE}2.${NC} Make sure your terminal font supports powerline symbols"
    echo -e "  ${BLUE}3.${NC} Customize your prompt by editing: ${GREEN}~/.config/starship.toml${NC}"
    echo ""
    echo -e "${YELLOW}Recommended terminal fonts:${NC}"
    echo -e "  • ${GREEN}FiraCode Nerd Font${NC}"
    echo -e "  • ${GREEN}JetBrains Mono Nerd Font${NC}"
    echo -e "  • ${GREEN}Any Nerd Font from https://www.nerdfonts.com/${NC}"
    echo ""
    echo -e "${YELLOW}Theme installed:${NC} ${GREEN}Catppuccin Powerline${NC}"
    echo ""
    echo -e "${CYAN}Enjoy your new beautiful prompt! ✨${NC}"
}

# Main function
main() {
    log_header "Starship Installation Script"
    
    echo -e "${CYAN}This script will install Starship.rs with Catppuccin Powerline theme${NC}"
    echo -e "${YELLOW}Press Enter to continue or Ctrl+C to cancel...${NC}"
    read -r
    
    detect_os
    detect_shell
    install_starship
    configure_shell
    install_catppuccin_theme
    install_fonts
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