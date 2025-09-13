#!/bin/bash

# =============================================================================
# QEMU Guest Agent Installation Script
# =============================================================================
# Installs QEMU Guest Agent if running in a KVM/QEMU virtual machine
# Supports: macOS, Ubuntu/Debian, Arch Linux, Fedora/RHEL/CentOS
# Includes: VM detection and automatic service management
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

# Function to detect virtualization
detect_virtualization() {
    log_header "Detecting Virtualization Environment"
    
    VM_TYPE=""
    IS_VM=false
    
    case $OS in
        "macos")
            # Check for VM indicators on macOS
            if system_profiler SPHardwareDataType | grep -q "VMware\|Parallels\|VirtualBox\|QEMU"; then
                IS_VM=true
                if system_profiler SPHardwareDataType | grep -q "VMware"; then
                    VM_TYPE="VMware"
                elif system_profiler SPHardwareDataType | grep -q "Parallels"; then
                    VM_TYPE="Parallels"
                elif system_profiler SPHardwareDataType | grep -q "VirtualBox"; then
                    VM_TYPE="VirtualBox"
                elif system_profiler SPHardwareDataType | grep -q "QEMU"; then
                    VM_TYPE="QEMU/KVM"
                fi
            fi
            
            # Alternative check using ioreg
            if ioreg -l | grep -q "VMware\|Parallels\|VirtualBox\|QEMU"; then
                IS_VM=true
                if [[ -z "$VM_TYPE" ]]; then
                    VM_TYPE="Unknown VM"
                fi
            fi
            ;;
            
        "linux")
            # Use systemd-detect-virt if available
            if command_exists systemd-detect-virt; then
                VIRT_TYPE=$(systemd-detect-virt 2>/dev/null || echo "none")
                if [[ "$VIRT_TYPE" != "none" ]]; then
                    IS_VM=true
                    VM_TYPE="$VIRT_TYPE"
                fi
            else
                # Fallback methods for systems without systemd-detect-virt
                
                # Check DMI information
                if [[ -r /sys/class/dmi/id/product_name ]]; then
                    PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
                    case "$PRODUCT_NAME" in
                        *"VMware"*)
                            IS_VM=true
                            VM_TYPE="VMware"
                            ;;
                        *"VirtualBox"*)
                            IS_VM=true
                            VM_TYPE="VirtualBox"
                            ;;
                        *"QEMU"*)
                            IS_VM=true
                            VM_TYPE="QEMU/KVM"
                            ;;
                        *"KVM"*)
                            IS_VM=true
                            VM_TYPE="QEMU/KVM"
                            ;;
                    esac
                fi
                
                # Check for hypervisor flag in /proc/cpuinfo
                if grep -q "hypervisor" /proc/cpuinfo 2>/dev/null; then
                    IS_VM=true
                    if [[ -z "$VM_TYPE" ]]; then
                        VM_TYPE="Unknown Hypervisor"
                    fi
                fi
                
                # Check for VM-specific modules
                if lsmod 2>/dev/null | grep -q "virtio\|vmw_\|vbox"; then
                    IS_VM=true
                    if lsmod | grep -q "virtio"; then
                        VM_TYPE="QEMU/KVM"
                    elif lsmod | grep -q "vmw_"; then
                        VM_TYPE="VMware"
                    elif lsmod | grep -q "vbox"; then
                        VM_TYPE="VirtualBox"
                    fi
                fi
                
                # Check /proc/scsi/scsi for VM disk signatures
                if [[ -r /proc/scsi/scsi ]] && grep -q "QEMU\|VBOX\|VMware" /proc/scsi/scsi 2>/dev/null; then
                    IS_VM=true
                    if grep -q "QEMU" /proc/scsi/scsi; then
                        VM_TYPE="QEMU/KVM"
                    elif grep -q "VBOX" /proc/scsi/scsi; then
                        VM_TYPE="VirtualBox"
                    elif grep -q "VMware" /proc/scsi/scsi; then
                        VM_TYPE="VMware"
                    fi
                fi
            fi
            ;;
    esac
    
    if [[ "$IS_VM" == true ]]; then
        log_success "Virtual machine detected: $VM_TYPE"
        
        # Check if it's QEMU/KVM specifically
        if [[ "$VM_TYPE" == "QEMU/KVM" ]] || [[ "$VM_TYPE" == "qemu" ]] || [[ "$VM_TYPE" == "kvm" ]]; then
            log_info "QEMU/KVM environment detected - QEMU Guest Agent installation recommended"
            return 0
        else
            log_info "Non-QEMU virtual machine detected ($VM_TYPE)"
            log_info "QEMU Guest Agent is not needed for this virtualization platform"
            return 1
        fi
    else
        log_info "Physical machine detected - QEMU Guest Agent is not needed"
        return 1
    fi
}

# Function to install QEMU Guest Agent
install_qemu_guest_agent() {
    log_header "Installing QEMU Guest Agent"
    
    case $DISTRO in
        "ubuntu"|"debian")
            log_info "Installing qemu-guest-agent via apt..."
            sudo apt update
            sudo apt install -y qemu-guest-agent
            
            # Enable and start the service
            log_info "Enabling and starting qemu-guest-agent service..."
            sudo systemctl enable qemu-guest-agent
            sudo systemctl start qemu-guest-agent
            ;;
            
        "arch"|"manjaro")
            log_info "Installing qemu-guest-agent via pacman..."
            sudo pacman -S --noconfirm qemu-guest-agent
            
            # Enable and start the service
            log_info "Enabling and starting qemu-guest-agent service..."
            sudo systemctl enable qemu-guest-agent
            sudo systemctl start qemu-guest-agent
            ;;
            
        "fedora"|"rhel"|"centos")
            if command_exists dnf; then
                log_info "Installing qemu-guest-agent via dnf..."
                sudo dnf install -y qemu-guest-agent
            else
                log_info "Installing qemu-guest-agent via yum..."
                sudo yum install -y qemu-guest-agent
            fi
            
            # Enable and start the service
            log_info "Enabling and starting qemu-guest-agent service..."
            sudo systemctl enable qemu-guest-agent
            sudo systemctl start qemu-guest-agent
            ;;
            
        "macos")
            log_warning "QEMU Guest Agent is not available for macOS"
            log_info "macOS VMs typically use different guest tools"
            return 1
            ;;
            
        *)
            log_error "Unsupported distribution for QEMU Guest Agent installation: $DISTRO"
            return 1
            ;;
    esac
    
    log_success "QEMU Guest Agent installed successfully"
}

# Function to verify installation and service status
verify_installation() {
    log_header "Verifying Installation"
    
    case $OS in
        "linux")
            # Check if service is installed and running
            if systemctl is-enabled qemu-guest-agent >/dev/null 2>&1; then
                log_success "qemu-guest-agent service is enabled"
                
                if systemctl is-active qemu-guest-agent >/dev/null 2>&1; then
                    log_success "qemu-guest-agent service is running"
                else
                    log_warning "qemu-guest-agent service is not running"
                    log_info "Service status: $(systemctl status qemu-guest-agent --no-pager -l)"
                fi
            else
                log_error "qemu-guest-agent service is not enabled"
                return 1
            fi
            
            # Check if the agent is communicating
            if [[ -e /dev/virtio-ports/org.qemu.guest_agent.0 ]]; then
                log_success "QEMU Guest Agent communication channel found"
            else
                log_warning "QEMU Guest Agent communication channel not found"
                log_info "This might be normal if the VM host doesn't support guest agent communication"
            fi
            ;;
            
        "macos")
            log_info "Verification not applicable for macOS"
            ;;
    esac
}

# Function to show completion message
show_completion_message() {
    log_header "Installation Complete!"
    
    echo -e "${GREEN}"
    cat << 'EOF'
     ██████╗ ███████╗███╗   ███╗██╗   ██╗
    ██╔═══██╗██╔════╝████╗ ████║██║   ██║
    ██║   ██║█████╗  ██╔████╔██║██║   ██║
    ██║▄▄ ██║██╔══╝  ██║╚██╔╝██║██║   ██║
    ╚██████╔╝███████╗██║ ╚═╝ ██║╚██████╔╝
     ╚══▀▀═╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝ 
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}🚀 QEMU Guest Agent has been successfully installed!${NC}"
    echo ""
    echo -e "${YELLOW}What this enables:${NC}"
    echo -e "  • ${GREEN}Better VM performance monitoring${NC}"
    echo -e "  • ${GREEN}Coordinated VM snapshots${NC}"
    echo -e "  • ${GREEN}Graceful VM shutdown from host${NC}"
    echo -e "  • ${GREEN}Time synchronization${NC}"
    echo -e "  • ${GREEN}File system freeze/thaw for backups${NC}"
    echo ""
    echo -e "${YELLOW}Service management:${NC}"
    echo -e "  • ${GREEN}Check status:${NC} sudo systemctl status qemu-guest-agent"
    echo -e "  • ${GREEN}Restart:${NC} sudo systemctl restart qemu-guest-agent"
    echo -e "  • ${GREEN}View logs:${NC} sudo journalctl -u qemu-guest-agent"
    echo ""
    echo -e "${CYAN}Your VM is now optimally configured! 🎉${NC}"
}

# Main function
main() {
    log_header "QEMU Guest Agent Installation Script"
    
    echo -e "${CYAN}This script will install QEMU Guest Agent if running in a QEMU/KVM VM${NC}"
    echo -e "${YELLOW}Press Enter to continue or Ctrl+C to cancel...${NC}"
    read -r
    
    detect_os
    
    if detect_virtualization; then
        # Check if already installed
        case $OS in
            "linux")
                if systemctl is-enabled qemu-guest-agent >/dev/null 2>&1; then
                    log_info "QEMU Guest Agent is already installed and enabled"
                    if systemctl is-active qemu-guest-agent >/dev/null 2>&1; then
                        log_success "QEMU Guest Agent is running"
                    else
                        log_warning "QEMU Guest Agent is installed but not running"
                        log_info "Starting the service..."
                        sudo systemctl start qemu-guest-agent
                    fi
                else
                    install_qemu_guest_agent
                fi
                ;;
            *)
                install_qemu_guest_agent
                ;;
        esac
        
        verify_installation
        show_completion_message
    else
        echo -e "${YELLOW}QEMU Guest Agent installation skipped${NC}"
        echo -e "${CYAN}This system does not appear to be running in a QEMU/KVM environment${NC}"
        echo ""
        echo -e "${BLUE}If you believe this is incorrect, you can manually install with:${NC}"
        case $DISTRO in
            "ubuntu"|"debian")
                echo -e "  ${GREEN}sudo apt install qemu-guest-agent${NC}"
                ;;
            "arch"|"manjaro")
                echo -e "  ${GREEN}sudo pacman -S qemu-guest-agent${NC}"
                ;;
            "fedora"|"rhel"|"centos")
                echo -e "  ${GREEN}sudo dnf install qemu-guest-agent${NC}"
                ;;
        esac
    fi
}

# Handle script interruption
trap 'log_error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"