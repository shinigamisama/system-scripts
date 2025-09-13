#!/bin/bash

# =============================================================================
# Quick System Setup - Install All Scripts
# =============================================================================
# Runs all system setup scripts in the correct order
# Includes: QEMU Guest Agent, DNS, Zoxide, Starship, LazyVim
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

# Base URL for scripts (GitHub raw)
BASE_URL="https://raw.githubusercontent.com/shinigamisama/system-scripts/main"

# Scripts to install (in order)
declare -A SCRIPTS=(
    ["qemu"]="installQemuGuestAgent.sh"
    ["zoxide"]="installZoxide.sh"
    ["starship"]="installStarship.sh"
    ["lazyvim"]="installLazyVim.sh"
)

# Interactive scripts (require user interaction)
INTERACTIVE_SCRIPTS=("setDNSNetplan.sh")

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to download and execute a script
install_script() {
    local script_name="$1"
    local display_name="$2"
    local url="$BASE_URL/$script_name"
    
    log_header "Installing $display_name"
    
    log_info "Downloading $script_name..."
    if curl -fsSL "$url" -o "/tmp/$script_name"; then
        chmod +x "/tmp/$script_name"
        log_success "Downloaded $script_name"
        
        log_info "Executing $script_name..."
        if bash "/tmp/$script_name"; then
            log_success "$display_name installed successfully!"
            rm -f "/tmp/$script_name"
            return 0
        else
            log_error "$display_name installation failed"
            rm -f "/tmp/$script_name"
            return 1
        fi
    else
        log_error "Failed to download $script_name"
        return 1
    fi
}

# Function to show script information
show_script_info() {
    echo ""
    log_header "Available Scripts"
    echo ""
    echo -e "${CYAN}Non-interactive scripts (will run automatically):${NC}"
    echo -e "  ${GREEN}1. QEMU Guest Agent${NC} - Enhanced VM performance (QEMU/KVM only)"
    echo -e "  ${GREEN}2. Zoxide${NC} - Smart directory navigation (cd replacement)"
    echo -e "  ${GREEN}3. Starship${NC} - Beautiful terminal prompt"
    echo -e "  ${GREEN}4. LazyVim${NC} - Modern Neovim configuration"
    echo ""
    echo -e "${CYAN}Interactive scripts (require manual execution):${NC}"
    echo -e "  ${GREEN}• DNS Configuration${NC} - Configure DNS servers with netplan (Ubuntu)"
    echo ""
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
        OS="unknown"
        DISTRO="Unknown"
    fi
    
    log_info "Detected OS: $DISTRO"
}

# Function to show completion message
show_completion_message() {
    log_header "Installation Summary"
    
    echo -e "${GREEN}"
    cat << 'EOF'
    ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗
    ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║
    ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║
    ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║
    ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║
    ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝
     ███████╗███████╗████████╗██╗   ██╗██████╗ 
     ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
     ███████╗█████╗     ██║   ██║   ██║██████╔╝
     ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ 
     ███████║███████╗   ██║   ╚██████╔╝██║     
     ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}🎉 System setup completed!${NC}"
    echo ""
    echo -e "${YELLOW}Installed components:${NC}"
    echo -e "  ${GREEN}✓ QEMU Guest Agent${NC} - Enhanced VM integration"
    echo -e "  ${GREEN}✓ Zoxide${NC} - Smart directory navigation" 
    echo -e "  ${GREEN}✓ Starship${NC} - Beautiful terminal prompt"
    echo -e "  ${GREEN}✓ LazyVim${NC} - Modern Neovim configuration"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  ${BLUE}1.${NC} Restart your terminal or run: ${GREEN}source ~/.bashrc${NC} (or ~/.zshrc)"
    echo -e "  ${BLUE}2.${NC} For DNS configuration (Ubuntu only): ${GREEN}curl -sSL $BASE_URL/setDNSNetplan.sh | sudo bash${NC}"
    echo -e "  ${BLUE}3.${NC} Start using your new tools!"
    echo ""
    echo -e "${YELLOW}Quick commands:${NC}"
    echo -e "  ${GREEN}cd project${NC} - Navigate with zoxide"
    echo -e "  ${GREEN}nvim${NC} or ${GREEN}lv${NC} - Start LazyVim"
    echo ""
    echo -e "${CYAN}Happy coding! 🚀${NC}"
}

# Main function
main() {
    log_header "Quick System Setup"
    
    echo -e "${CYAN}This script will install essential development tools${NC}"
    echo -e "${CYAN}for an improved terminal and development experience.${NC}"
    echo ""
    
    detect_os
    show_script_info
    
    echo -e "${YELLOW}Do you want to proceed with the installation? (y/N)${NC}"
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    local failed_count=0
    local success_count=0
    local total_count=${#SCRIPTS[@]}
    
    log_info "Starting installation of $total_count components..."
    echo ""
    
    # Install each script
    for name in qemu zoxide starship lazyvim; do
        script_name="${SCRIPTS[$name]}"
        display_name=""
        
        case $name in
            "qemu") display_name="QEMU Guest Agent" ;;
            "zoxide") display_name="Zoxide" ;;
            "starship") display_name="Starship" ;;
            "lazyvim") display_name="LazyVim" ;;
        esac
        
        if install_script "$script_name" "$display_name"; then
            ((success_count++))
        else
            ((failed_count++))
            log_warning "Failed to install $display_name, continuing..."
        fi
        
        echo ""
        sleep 1  # Brief pause between installations
    done
    
    # Show results
    log_header "Installation Results"
    echo -e "${GREEN}✓ Successfully installed: $success_count/$total_count${NC}"
    if [[ $failed_count -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Failed installations: $failed_count/$total_count${NC}"
    fi
    
    echo ""
    
    # Show additional scripts available
    if [[ ${#INTERACTIVE_SCRIPTS[@]} -gt 0 ]]; then
        log_info "Interactive scripts available for manual installation:"
        for script in "${INTERACTIVE_SCRIPTS[@]}"; do
            echo -e "  ${CYAN}$BASE_URL/$script${NC}"
        done
        echo ""
    fi
    
    if [[ $success_count -gt 0 ]]; then
        show_completion_message
    else
        log_error "All installations failed. Please check your internet connection and try again."
        exit 1
    fi
}

# Handle script interruption
trap 'log_error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"