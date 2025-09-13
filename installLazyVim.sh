#!/bin/bash

# =============================================================================
# LazyVim Installation Script
# =============================================================================
# Installs LazyVim with automatic OS detection and build tools
# Supports: macOS, Ubuntu/Debian, Arch Linux, Fedora/RHEL/CentOS
# Includes: Build tools, compilers, and all necessary dependencies
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

# Function to install dependencies based on OS
install_dependencies() {
    log_header "Installing Dependencies"
    
    case $DISTRO in
        "macos")
            # Check if Homebrew is installed
            if ! command_exists brew; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Add Homebrew to PATH for Apple Silicon Macs
                if [[ $(uname -m) == "arm64" ]]; then
                    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            fi
            
            # Install dependencies
            brew install neovim git curl wget ripgrep fd lazygit
            
            # Install build tools (Xcode Command Line Tools)
            if ! xcode-select -p &> /dev/null; then
                log_info "Installing Xcode Command Line Tools..."
                xcode-select --install
                log_warning "Please complete the Xcode Command Line Tools installation when prompted"
                log_warning "Press Enter after the installation is complete..."
                read -r
            else
                log_info "Xcode Command Line Tools already installed"
            fi
            ;;
            
        "ubuntu"|"debian")
            log_info "Updating package lists..."
            sudo apt update
            
            log_info "Installing build tools and dependencies..."
            sudo apt install -y build-essential cmake pkg-config libssl-dev
            sudo apt install -y neovim git curl wget ripgrep fd-find
            
            # Install lazygit (not in default repos)
            if ! command_exists lazygit; then
                log_info "Installing lazygit..."
                LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
                tar xf lazygit.tar.gz lazygit
                sudo install lazygit /usr/local/bin
                rm lazygit lazygit.tar.gz
            fi
            ;;
            
        "arch"|"manjaro")
            log_info "Updating package database..."
            sudo pacman -Sy
            
            log_info "Installing build tools and dependencies..."
            sudo pacman -S --noconfirm base-devel cmake pkg-config openssl
            sudo pacman -S --noconfirm neovim git curl wget ripgrep fd lazygit
            ;;
            
        "fedora"|"rhel"|"centos")
            log_info "Installing build tools and dependencies..."
            if command_exists dnf; then
                # Install build tools first
                sudo dnf groupinstall -y "Development Tools"
                sudo dnf install -y cmake pkg-config openssl-devel
                sudo dnf install -y neovim git curl wget ripgrep fd-find
            else
                # For older RHEL/CentOS with yum
                sudo yum groupinstall -y "Development Tools"
                sudo yum install -y cmake pkg-config openssl-devel
                sudo yum install -y neovim git curl wget
                log_warning "ripgrep and fd-find may not be available in default repos"
            fi
            
            # Install lazygit
            if ! command_exists lazygit; then
                log_info "Installing lazygit..."
                sudo dnf copr enable atim/lazygit -y 2>/dev/null || true
                sudo dnf install -y lazygit 2>/dev/null || {
                    log_warning "Installing lazygit manually..."
                    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
                    tar xf lazygit.tar.gz lazygit
                    sudo install lazygit /usr/local/bin
                    rm lazygit lazygit.tar.gz
                }
            fi
            ;;
            
        *)
            log_error "Unsupported Linux distribution: $DISTRO"
            log_info "Please install manually: neovim, git, curl, wget, ripgrep, fd, lazygit"
            exit 1
            ;;
    esac
    
    log_success "Dependencies installed successfully!"
}

# Function to backup existing Neovim config
backup_config() {
    log_header "Backing Up Existing Configuration"
    
    NVIM_CONFIG_DIR=""
    NVIM_DATA_DIR=""
    NVIM_STATE_DIR=""
    NVIM_CACHE_DIR=""
    
    case $OS in
        "macos")
            NVIM_CONFIG_DIR="$HOME/.config/nvim"
            NVIM_DATA_DIR="$HOME/.local/share/nvim"
            NVIM_STATE_DIR="$HOME/.local/state/nvim"
            NVIM_CACHE_DIR="$HOME/.cache/nvim"
            ;;
        "linux")
            NVIM_CONFIG_DIR="$HOME/.config/nvim"
            NVIM_DATA_DIR="$HOME/.local/share/nvim"
            NVIM_STATE_DIR="$HOME/.local/state/nvim"
            NVIM_CACHE_DIR="$HOME/.cache/nvim"
            ;;
    esac
    
    BACKUP_DIR="$HOME/nvim-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [[ -d "$NVIM_CONFIG_DIR" ]]; then
        log_info "Backing up existing Neovim configuration to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        
        [[ -d "$NVIM_CONFIG_DIR" ]] && cp -r "$NVIM_CONFIG_DIR" "$BACKUP_DIR/nvim-config"
        [[ -d "$NVIM_DATA_DIR" ]] && cp -r "$NVIM_DATA_DIR" "$BACKUP_DIR/nvim-data"
        [[ -d "$NVIM_STATE_DIR" ]] && cp -r "$NVIM_STATE_DIR" "$BACKUP_DIR/nvim-state"
        [[ -d "$NVIM_CACHE_DIR" ]] && cp -r "$NVIM_CACHE_DIR" "$BACKUP_DIR/nvim-cache"
        
        log_success "Backup completed: $BACKUP_DIR"
        
        # Clean existing directories
        rm -rf "$NVIM_CONFIG_DIR" "$NVIM_DATA_DIR" "$NVIM_STATE_DIR" "$NVIM_CACHE_DIR"
        log_info "Cleaned existing Neovim directories"
    else
        log_info "No existing Neovim configuration found"
    fi
}

# Function to install LazyVim
install_lazyvim() {
    log_header "Installing LazyVim"
    
    # Clone LazyVim starter template
    log_info "Cloning LazyVim starter template..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    
    # Remove .git directory to make it your own repo
    rm -rf "$HOME/.config/nvim/.git"
    
    log_success "LazyVim starter template installed!"
}

# Function to install Node.js (needed for many LSP servers)
install_nodejs() {
    log_header "Installing Node.js"
    
    if command_exists node; then
        log_info "Node.js already installed: $(node --version)"
        return
    fi
    
    case $DISTRO in
        "macos")
            if command_exists brew; then
                brew install node
            else
                log_warning "Please install Node.js manually from https://nodejs.org"
            fi
            ;;
        "ubuntu"|"debian")
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm nodejs npm
            ;;
        "fedora"|"rhel"|"centos")
            if command_exists dnf; then
                sudo dnf install -y nodejs npm
            else
                sudo yum install -y nodejs npm
            fi
            ;;
        *)
            log_warning "Please install Node.js manually from https://nodejs.org"
            ;;
    esac
    
    if command_exists node; then
        log_success "Node.js installed: $(node --version)"
    fi
}

# Function to install Python and pip
install_python() {
    log_header "Installing Python"
    
    if command_exists python3; then
        log_info "Python3 already installed: $(python3 --version)"
    else
        case $DISTRO in
            "macos")
                if command_exists brew; then
                    brew install python3
                fi
                ;;
            "ubuntu"|"debian")
                sudo apt install -y python3 python3-pip python3-venv
                ;;
            "arch"|"manjaro")
                sudo pacman -S --noconfirm python python-pip
                ;;
            "fedora"|"rhel"|"centos")
                if command_exists dnf; then
                    sudo dnf install -y python3 python3-pip python3-venv
                else
                    sudo yum install -y python3 python3-pip
                fi
                ;;
        esac
    fi
    
    # Install pynvim with proper handling of externally-managed environments
    if command_exists python3; then
        log_info "Installing pynvim..."
        
        # Try different installation methods based on system
        case $DISTRO in
            "macos")
                # On macOS, try pip3 with --user first, then brew if available
                if pip3 install --user pynvim 2>/dev/null; then
                    log_success "pynvim installed via pip3 --user"
                elif command_exists brew && brew install pynvim 2>/dev/null; then
                    log_success "pynvim installed via Homebrew"
                else
                    log_warning "Could not install pynvim automatically"
                    log_info "You can install it later with: pip3 install --user pynvim"
                fi
                ;;
            "ubuntu"|"debian")
                # Try system package first, then pipx, then --user
                if sudo apt install -y python3-pynvim 2>/dev/null; then
                    log_success "pynvim installed via system package"
                elif command_exists pipx && pipx install pynvim 2>/dev/null; then
                    log_success "pynvim installed via pipx"
                elif pip3 install --user pynvim --break-system-packages 2>/dev/null; then
                    log_success "pynvim installed via pip3 --user --break-system-packages"
                else
                    log_warning "Could not install pynvim automatically"
                    log_info "You can install it later with one of:"
                    log_info "  sudo apt install python3-pynvim"
                    log_info "  pipx install pynvim"
                    log_info "  pip3 install --user pynvim --break-system-packages"
                fi
                ;;
            "arch"|"manjaro")
                # Arch usually doesn't have this restriction
                if pip3 install --user pynvim 2>/dev/null; then
                    log_success "pynvim installed via pip3 --user"
                elif sudo pacman -S --noconfirm python-pynvim 2>/dev/null; then
                    log_success "pynvim installed via pacman"
                else
                    log_warning "Could not install pynvim automatically"
                fi
                ;;
            "fedora"|"rhel"|"centos")
                # Try system package first
                if sudo dnf install -y python3-pynvim 2>/dev/null; then
                    log_success "pynvim installed via system package"
                elif pip3 install --user pynvim 2>/dev/null; then
                    log_success "pynvim installed via pip3 --user"
                else
                    log_warning "Could not install pynvim automatically"
                fi
                ;;
            *)
                # Generic fallback
                if pip3 install --user pynvim 2>/dev/null; then
                    log_success "pynvim installed via pip3 --user"
                else
                    log_warning "Could not install pynvim automatically"
                    log_info "You may need to install it manually"
                fi
                ;;
        esac
    fi
}

# Function to setup shell integration
setup_shell_integration() {
    log_header "Setting Up Shell Integration"
    
    # Add useful aliases
    SHELL_RC=""
    if [[ $SHELL == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ $SHELL == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    
    if [[ -n "$SHELL_RC" && -f "$SHELL_RC" ]]; then
        # Add LazyVim alias if not exists
        if ! grep -q "alias lv=" "$SHELL_RC"; then
            echo "" >> "$SHELL_RC"
            echo "# LazyVim aliases" >> "$SHELL_RC"
            echo "alias lv='nvim'" >> "$SHELL_RC"
            echo "alias lazyvim='nvim'" >> "$SHELL_RC"
            log_success "Added LazyVim aliases to $SHELL_RC"
        fi
    fi
}

# Function to verify installation
verify_installation() {
    log_header "Verifying Installation"
    
    # Check if Neovim is installed
    if command_exists nvim; then
        NVIM_VERSION=$(nvim --version | head -n1)
        log_success "Neovim installed: $NVIM_VERSION"
    else
        log_error "Neovim not found!"
        return 1
    fi
    
    # Check if LazyVim config exists
    if [[ -f "$HOME/.config/nvim/init.lua" ]]; then
        log_success "LazyVim configuration found"
    else
        log_error "LazyVim configuration not found!"
        return 1
    fi
    
    # Check optional dependencies
    log_info "Checking optional dependencies..."
    command_exists git && log_success "✓ Git available" || log_warning "✗ Git not found"
    command_exists curl && log_success "✓ Curl available" || log_warning "✗ Curl not found"
    command_exists wget && log_success "✓ Wget available" || log_warning "✗ Wget not found"
    command_exists ripgrep && log_success "✓ Ripgrep available" || log_warning "✗ Ripgrep not found"
    command_exists fd && log_success "✓ Fd available" || log_warning "✗ Fd not found"
    command_exists lazygit && log_success "✓ Lazygit available" || log_warning "✗ Lazygit not found"
    command_exists node && log_success "✓ Node.js available" || log_warning "✗ Node.js not found"
    command_exists python3 && log_success "✓ Python3 available" || log_warning "✗ Python3 not found"
    
    # Check build tools
    log_info "Checking build tools..."
    case $DISTRO in
        "macos")
            xcode-select -p &> /dev/null && log_success "✓ Xcode Command Line Tools available" || log_warning "✗ Xcode Command Line Tools not found"
            ;;
        "ubuntu"|"debian")
            command_exists gcc && log_success "✓ GCC compiler available" || log_warning "✗ GCC not found"
            command_exists make && log_success "✓ Make available" || log_warning "✗ Make not found"
            command_exists cmake && log_success "✓ CMake available" || log_warning "✗ CMake not found"
            ;;
        "arch"|"manjaro")
            command_exists gcc && log_success "✓ GCC compiler available" || log_warning "✗ GCC not found"
            command_exists make && log_success "✓ Make available" || log_warning "✗ Make not found"
            ;;
        "fedora"|"rhel"|"centos")
            command_exists gcc && log_success "✓ GCC compiler available" || log_warning "✗ GCC not found"
            command_exists make && log_success "✓ Make available" || log_warning "✗ Make not found"
            ;;
    esac
}

# Function to show completion message
show_completion_message() {
    log_header "Installation Complete!"
    
    echo -e "${GREEN}"
    cat << 'EOF'
    ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗
    ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║
    ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║
    ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║
    ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║
    ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}🎉 LazyVim has been successfully installed!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  ${BLUE}1.${NC} Run ${GREEN}nvim${NC} or ${GREEN}lv${NC} to start LazyVim"
    echo -e "  ${BLUE}2.${NC} LazyVim will automatically install plugins on first run"
    echo -e "  ${BLUE}3.${NC} Press ${GREEN}:checkhealth${NC} in Neovim to verify everything is working"
    echo -e "  ${BLUE}4.${NC} Visit ${GREEN}https://www.lazyvim.org${NC} for documentation"
    echo ""
    echo -e "${YELLOW}Useful commands:${NC}"
    echo -e "  ${GREEN}<leader>l${NC}  - Open Lazy plugin manager"
    echo -e "  ${GREEN}<leader>e${NC}  - Open file explorer"
    echo -e "  ${GREEN}<leader>ff${NC} - Find files"
    echo -e "  ${GREEN}<leader>sg${NC} - Search in files"
    echo -e "  ${GREEN}<leader>gg${NC} - Open Lazygit"
    echo ""
    echo -e "${CYAN}Happy coding with LazyVim! 🚀${NC}"
}

# Main function
main() {
    log_header "LazyVim Installation Script"
    
    echo -e "${CYAN}This script will install LazyVim with all dependencies${NC}"
    echo -e "${YELLOW}Press Enter to continue or Ctrl+C to cancel...${NC}"
    read -r
    
    detect_os
    install_dependencies
    backup_config
    install_lazyvim
    install_nodejs
    install_python
    setup_shell_integration
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
