#!/bin/bash

# =============================================================================
# DNS Configuration Script for Ubuntu Netplan
# =============================================================================
# Automatically configures DNS servers using netplan on Ubuntu servers
# Supports: Multiple DNS providers, custom DNS, backup configurations
# Includes: Validation, backup, and rollback capabilities
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

# Configuration
NETPLAN_DIR="/etc/netplan"
BACKUP_DIR="/root/netplan-backups"
SCRIPT_NAME="$(basename "$0")"

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

# Function to check if running on Ubuntu
check_ubuntu() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS version"
        exit 1
    fi
    
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "This script is designed for Ubuntu servers only"
        log_error "Detected OS: $ID"
        exit 1
    fi
    
    log_info "Ubuntu $VERSION_ID detected"
}

# Function to check if netplan is available
check_netplan() {
    if ! command -v netplan >/dev/null 2>&1; then
        log_error "Netplan is not installed or not available"
        exit 1
    fi
    
    if [[ ! -d "$NETPLAN_DIR" ]]; then
        log_error "Netplan directory not found: $NETPLAN_DIR"
        exit 1
    fi
    
    # Check for Python3 and PyYAML for configuration parsing
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import yaml" 2>/dev/null; then
            log_info "Python3 with PyYAML available for configuration parsing"
            HAS_YAML_SUPPORT=true
        else
            log_warning "Python3 found but PyYAML not available"
            log_info "Installing PyYAML for better configuration handling..."
            if pip3 install PyYAML 2>/dev/null || pip3 install --user PyYAML 2>/dev/null; then
                HAS_YAML_SUPPORT=true
                log_success "PyYAML installed successfully"
            else
                log_warning "Could not install PyYAML, will use basic text processing"
                HAS_YAML_SUPPORT=false
            fi
        fi
    else
        log_warning "Python3 not available, will use basic text processing"
        HAS_YAML_SUPPORT=false
    fi
    
    log_info "Netplan is available"
}

# Function to check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        log_info "Please run: sudo $0"
        exit 1
    fi
}

# Function to show available DNS providers
show_dns_providers() {
    echo -e "${CYAN}Available DNS Providers:${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} ${GREEN}Cloudflare${NC}        - 1.1.1.1, 1.0.0.1 (Fast, Privacy-focused)"
    echo -e "${YELLOW}2.${NC} ${GREEN}Google${NC}            - 8.8.8.8, 8.8.4.4 (Reliable, Fast)"
    echo -e "${YELLOW}3.${NC} ${GREEN}Quad9${NC}             - 9.9.9.9, 149.112.112.112 (Security-focused)"
    echo -e "${YELLOW}4.${NC} ${GREEN}OpenDNS${NC}           - 208.67.222.222, 208.67.220.220 (Family-safe)"
    echo -e "${YELLOW}5.${NC} ${GREEN}AdGuard${NC}           - 94.140.14.14, 94.140.15.15 (Ad-blocking)"
    echo -e "${YELLOW}6.${NC} ${GREEN}NextDNS${NC}           - 45.90.28.0, 45.90.30.0 (Customizable)"
    echo -e "${YELLOW}7.${NC} ${GREEN}Custom${NC}            - Enter your own DNS servers"
    echo -e "${YELLOW}8.${NC} ${GREEN}Show current${NC}      - Display current DNS configuration"
    echo -e "${YELLOW}9.${NC} ${GREEN}Restore backup${NC}    - Restore previous configuration"
    echo ""
}

# Function to get DNS servers for provider
get_dns_servers() {
    local provider="$1"
    
    case $provider in
        "1"|"cloudflare")
            DNS_SERVERS=("1.1.1.1" "1.0.0.1")
            DNS_NAME="Cloudflare"
            ;;
        "2"|"google")
            DNS_SERVERS=("8.8.8.8" "8.8.4.4")
            DNS_NAME="Google"
            ;;
        "3"|"quad9")
            DNS_SERVERS=("9.9.9.9" "149.112.112.112")
            DNS_NAME="Quad9"
            ;;
        "4"|"opendns")
            DNS_SERVERS=("208.67.222.222" "208.67.220.220")
            DNS_NAME="OpenDNS"
            ;;
        "5"|"adguard")
            DNS_SERVERS=("94.140.14.14" "94.140.15.15")
            DNS_NAME="AdGuard"
            ;;
        "6"|"nextdns")
            DNS_SERVERS=("45.90.28.0" "45.90.30.0")
            DNS_NAME="NextDNS"
            ;;
        "7"|"custom")
            get_custom_dns
            ;;
        *)
            log_error "Invalid DNS provider selection"
            return 1
            ;;
    esac
    
    return 0
}

# Function to get custom DNS servers
get_custom_dns() {
    DNS_SERVERS=()
    DNS_NAME="Custom"
    
    echo -e "${YELLOW}Enter custom DNS servers (press Enter when done):${NC}"
    
    local count=1
    while true; do
        echo -n "DNS Server $count (or press Enter to finish): "
        read -r dns_server
        
        if [[ -z "$dns_server" ]]; then
            if [[ ${#DNS_SERVERS[@]} -eq 0 ]]; then
                log_error "At least one DNS server must be specified"
                continue
            else
                break
            fi
        fi
        
        # Validate IP address
        if validate_ip "$dns_server"; then
            DNS_SERVERS+=("$dns_server")
            log_success "Added DNS server: $dns_server"
            ((count++))
        else
            log_error "Invalid IP address: $dns_server"
        fi
        
        if [[ ${#DNS_SERVERS[@]} -ge 4 ]]; then
            log_warning "Maximum 4 DNS servers recommended"
            echo -n "Add more? (y/N): "
            read -r continue_adding
            if [[ ! "$continue_adding" =~ ^[Yy]$ ]]; then
                break
            fi
        fi
    done
}

# Function to validate IP address
validate_ip() {
    local ip="$1"
    local regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    
    if [[ ! $ip =~ $regex ]]; then
        return 1
    fi
    
    IFS='.' read -ra ADDR <<< "$ip"
    for i in "${ADDR[@]}"; do
        if [[ $i -gt 255 ]]; then
            return 1
        fi
    done
    
    return 0
}

# Function to find netplan configuration file
find_netplan_config() {
    # Look for existing netplan files
    local config_files=($(find "$NETPLAN_DIR" -name "*.yaml" -o -name "*.yml" | sort))
    
    if [[ ${#config_files[@]} -eq 0 ]]; then
        log_warning "No existing netplan configuration found"
        NETPLAN_CONFIG="$NETPLAN_DIR/01-dns-config.yaml"
        log_info "Will create new configuration: $NETPLAN_CONFIG"
    elif [[ ${#config_files[@]} -eq 1 ]]; then
        NETPLAN_CONFIG="${config_files[0]}"
        log_info "Using existing configuration: $NETPLAN_CONFIG"
    else
        log_info "Multiple netplan configurations found:"
        for i in "${!config_files[@]}"; do
            echo -e "  ${YELLOW}$((i+1)).${NC} ${config_files[i]}"
        done
        
        echo -n "Select configuration file (1-${#config_files[@]}): "
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#config_files[@]} ]]; then
            NETPLAN_CONFIG="${config_files[$((selection-1))]}"
            log_info "Selected configuration: $NETPLAN_CONFIG"
        else
            log_error "Invalid selection"
            exit 1
        fi
    fi
}

# Function to backup current configuration
backup_config() {
    log_header "Backing Up Current Configuration"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Create timestamp
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local backup_file="$BACKUP_DIR/netplan-backup-$timestamp.yaml"
    
    if [[ -f "$NETPLAN_CONFIG" ]]; then
        cp "$NETPLAN_CONFIG" "$backup_file"
        log_success "Configuration backed up to: $backup_file"
        echo "$backup_file" > "$BACKUP_DIR/latest-backup.txt"
    else
        log_info "No existing configuration to backup"
        echo "none" > "$BACKUP_DIR/latest-backup.txt"
    fi
}

# Function to detect network interface
detect_interface() {
    log_info "Detecting physical network interfaces..."
    
    # Get all network interfaces except loopback and virtual interfaces
    local all_interfaces=($(ip link show | awk -F': ' '/^[0-9]+:/ && !/lo:/ {print $2}' | cut -d'@' -f1))
    local interfaces=()
    
    # Filter out virtual interfaces (Docker, containers, bridges, etc.)
    for iface in "${all_interfaces[@]}"; do
        # Skip virtual interfaces by common naming patterns
        if [[ "$iface" =~ ^(docker|br-|veth|virbr|lxc|tun|tap|wg|ppp) ]]; then
            continue
        fi
        
        # Skip interfaces that are clearly virtual based on additional checks
        local iface_type=""
        if [[ -f "/sys/class/net/$iface/type" ]]; then
            iface_type=$(cat "/sys/class/net/$iface/type" 2>/dev/null)
        fi
        
        # Type 1 = Ethernet, Type 6 = IEEE 802.11 (WiFi)
        # Skip other types like bridges (Type 512), tunnels, etc.
        if [[ "$iface_type" != "1" ]] && [[ "$iface_type" != "6" ]]; then
            # Check if it's a physical interface by looking for a device path
            if [[ ! -d "/sys/class/net/$iface/device" ]] && [[ ! -f "/sys/class/net/$iface/wireless/name" ]]; then
                continue
            fi
        fi
        
        # Add to filtered list
        interfaces+=("$iface")
    done
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        log_error "No physical network interfaces found"
        log_info "Available interfaces (including virtual):"
        for iface in "${all_interfaces[@]}"; do
            echo "  - $iface"
        done
        exit 1
    elif [[ ${#interfaces[@]} -eq 1 ]]; then
        INTERFACE="${interfaces[0]}"
        log_info "Using physical interface: $INTERFACE"
    else
        log_info "Multiple physical interfaces found:"
        for i in "${!interfaces[@]}"; do
            local status=$(ip link show "${interfaces[i]}" | grep -o "state [A-Z]*" | cut -d' ' -f2)
            local iface_info=""
            
            # Try to get interface description/type
            if [[ -f "/sys/class/net/${interfaces[i]}/device/modalias" ]]; then
                iface_info=" [Physical]"
            elif [[ -d "/sys/class/net/${interfaces[i]}/wireless" ]]; then
                iface_info=" [WiFi]"
            else
                iface_info=" [Ethernet]"
            fi
            
            echo -e "  ${YELLOW}$((i+1)).${NC} ${interfaces[i]} (${status})${iface_info}"
        done
        
        echo -n "Select interface (1-${#interfaces[@]}): "
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#interfaces[@]} ]]; then
            INTERFACE="${interfaces[$((selection-1))]}"
            log_info "Selected interface: $INTERFACE"
        else
            log_error "Invalid selection"
            exit 1
        fi
    fi
}

# Function to create netplan configuration
create_netplan_config() {
    log_header "Creating Netplan Configuration"
    
    local temp_config="/tmp/netplan-temp-$$.yaml"
    
    # Check if we have an existing configuration to preserve
    if [[ -f "$NETPLAN_CONFIG" ]]; then
        log_info "Preserving existing network configuration..."
        
        if [[ "$HAS_YAML_SUPPORT" == true ]]; then
            # Use Python with PyYAML for proper YAML parsing
            log_info "Using advanced YAML parsing to preserve all settings..."
            parse_yaml_with_python
        else
            # Use basic text processing fallback
            log_info "Using basic text processing to preserve settings..."
            parse_yaml_with_text_processing
        fi
    else
        log_info "No existing configuration found, creating new one..."
        create_new_netplan_config
    fi
    
    log_info "DNS Provider: $DNS_NAME"
    log_info "DNS Servers: $(IFS=', '; echo "${DNS_SERVERS[*]}")"
}

# Function to parse YAML using Python
parse_yaml_with_python() {
    python3 -c "
import yaml
import sys

# DNS servers to set
dns_servers = [$(printf '"%s",' "${DNS_SERVERS[@]}" | sed 's/,$//')]  
interface_name = '$INTERFACE'

try:
    # Load existing config
    with open('$NETPLAN_CONFIG', 'r') as f:
        config = yaml.safe_load(f) or {}
    
    # Ensure structure exists
    if 'network' not in config:
        config['network'] = {}
    if 'version' not in config['network']:
        config['network']['version'] = 2
    if 'renderer' not in config['network']:
        config['network']['renderer'] = 'networkd'
    
    # Handle both ethernets and wifis sections
    for section in ['ethernets', 'wifis']:
        if section in config['network']:
            if interface_name in config['network'][section]:
                # Update DNS for this interface
                config['network'][section][interface_name]['nameservers'] = {
                    'addresses': dns_servers
                }
                # Add dhcp4-overrides to disable DHCP DNS
                if 'dhcp4' in config['network'][section][interface_name]:
                    if config['network'][section][interface_name]['dhcp4']:
                        config['network'][section][interface_name]['dhcp4-overrides'] = {
                            'use-dns': False
                        }
                break
    else:
        # Interface not found in existing config, add to ethernets
        if 'ethernets' not in config['network']:
            config['network']['ethernets'] = {}
        
        config['network']['ethernets'][interface_name] = {
            'dhcp4': True,
            'dhcp6': False,
            'nameservers': {'addresses': dns_servers},
            'dhcp4-overrides': {'use-dns': False}
        }
    
    # Write updated config
    with open('$temp_config', 'w') as f:
        yaml.dump(config, f, default_flow_style=False, indent=2)
    
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_config" "$NETPLAN_CONFIG"
        log_success "Existing configuration updated with new DNS settings"
    else
        log_error "Failed to update existing configuration, creating new one..."
        create_new_netplan_config
    fi
}

# Function to parse YAML using basic text processing
parse_yaml_with_text_processing() {
    local backup_temp="/tmp/netplan-simple-$$.yaml"
    cp "$NETPLAN_CONFIG" "$backup_temp"
    
    # Check if the interface already exists in the config
    if grep -q "^  *$INTERFACE:" "$NETPLAN_CONFIG"; then
        log_info "Interface $INTERFACE found in existing config, updating DNS only..."
        
        # Create a new config preserving everything except nameservers for this interface
        awk -v interface="$INTERFACE" -v dns_servers="$(printf '        - %s\n' "${DNS_SERVERS[@]}")" '
        BEGIN { 
            in_interface = 0
            in_nameservers = 0
            skip_nameservers = 0
        }
        /^[[:space:]]*[a-zA-Z0-9_-]+:[[:space:]]*$/ {
            if (match($0, "^[[:space:]]*" interface ":.*")) {
                in_interface = 1
            } else {
                in_interface = 0
            }
            in_nameservers = 0
            skip_nameservers = 0
        }
        /^[[:space:]]*nameservers:[[:space:]]*$/ {
            if (in_interface) {
                print $0
                print "        addresses:"
                print dns_servers
                in_nameservers = 1
                skip_nameservers = 1
                next
            }
        }
        /^[[:space:]]*addresses:[[:space:]]*$/ {
            if (in_interface && in_nameservers) {
                skip_nameservers = 1
                next
            }
        }
        /^[[:space:]]*-[[:space:]]*[0-9]/ {
            if (skip_nameservers) {
                next
            }
        }
        {
            if (!skip_nameservers) {
                print $0
            }
            if (match($0, "^[[:space:]]*[^[:space:]-]")) {
                skip_nameservers = 0
            }
        }
        ' "$backup_temp" > "$NETPLAN_CONFIG"
        
        # Add dhcp4-overrides if missing
        if ! grep -A 10 "^  *$INTERFACE:" "$NETPLAN_CONFIG" | grep -q "dhcp4-overrides:"; then
            if grep -A 10 "^  *$INTERFACE:" "$NETPLAN_CONFIG" | grep -q "dhcp4: true"; then
                sed -i "/^  *$INTERFACE:/,/^  *[a-zA-Z]/ s/dhcp4: true/dhcp4: true\n      dhcp4-overrides:\n        use-dns: false/" "$NETPLAN_CONFIG"
            fi
        fi
        
    else
        log_warning "Interface $INTERFACE not found in existing config"
        log_info "Adding DNS configuration for $INTERFACE..."
        
        # Add the interface to existing config
        local dns_block=""
        for dns in "${DNS_SERVERS[@]}"; do
            dns_block="${dns_block}        - ${dns}\n"
        done
        
        # Find if we have ethernets or wifis section
        if grep -q "^  ethernets:" "$NETPLAN_CONFIG"; then
            # Add to ethernets section
            sed -i "/^  ethernets:/a\\    $INTERFACE:\\      dhcp4: true\\      dhcp6: false\\      nameservers:\\        addresses:\\$(echo -e "$dns_block")      dhcp4-overrides:\\        use-dns: false" "$NETPLAN_CONFIG"
        else
            # Add ethernets section
            sed -i "/^network:/a\\  ethernets:\\    $INTERFACE:\\      dhcp4: true\\      dhcp6: false\\      nameservers:\\        addresses:\\$(echo -e "$dns_block")      dhcp4-overrides:\\        use-dns: false" "$NETPLAN_CONFIG"
        fi
    fi
    
    rm -f "$backup_temp"
    log_success "Configuration updated using text processing"
    else
        log_info "No existing configuration found, creating new one..."
        create_new_netplan_config
    fi
    
    log_info "DNS Provider: $DNS_NAME"
    log_info "DNS Servers: $(IFS=', '; echo "${DNS_SERVERS[*]}")"
}

# Function to create a new netplan configuration from scratch
create_new_netplan_config() {
    # Create DNS servers array for YAML
    local dns_list=""
    for dns in "${DNS_SERVERS[@]}"; do
        dns_list="${dns_list}        - ${dns}\n"
    done
    
    # Determine if this looks like a WiFi interface
    local is_wifi=false
    if [[ -d "/sys/class/net/$INTERFACE/wireless" ]] || [[ "$INTERFACE" =~ ^(wlan|wifi|wl) ]]; then
        is_wifi=true
        log_warning "Detected WiFi interface: $INTERFACE"
        log_warning "WiFi credentials need to be configured separately!"
    fi
    
    # Create the netplan configuration
    if [[ "$is_wifi" == true ]]; then
        cat > "$NETPLAN_CONFIG" << EOF
network:
  version: 2
  renderer: networkd
  wifis:
    $INTERFACE:
      dhcp4: true
      dhcp6: false
      access-points:
        # Add your WiFi network here:
        # "YOUR_WIFI_SSID":
        #   password: "YOUR_WIFI_PASSWORD"
      nameservers:
        addresses:
$(echo -e "$dns_list")
      dhcp4-overrides:
        use-dns: false
EOF
        log_warning "WiFi interface detected but no existing configuration found!"
        log_warning "You need to manually edit $NETPLAN_CONFIG to add WiFi credentials"
    else
        cat > "$NETPLAN_CONFIG" << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: true
      dhcp6: false
      nameservers:
        addresses:
$(echo -e "$dns_list")
      dhcp4-overrides:
        use-dns: false
EOF
    fi
}

# Function to validate netplan configuration
validate_config() {
    log_header "Validating Configuration"
    
    if netplan try --timeout 10 2>/dev/null; then
        log_success "Configuration validation passed"
        return 0
    else
        log_error "Configuration validation failed"
        return 1
    fi
}

# Function to apply configuration
apply_config() {
    log_header "Applying Configuration"
    
    # Try to apply with timeout
    log_info "Applying netplan configuration..."
    if timeout 30 netplan apply; then
        log_success "Configuration applied successfully"
        
        # Wait a moment for changes to take effect
        sleep 3
        
        # Verify DNS resolution
        verify_dns
    else
        log_error "Failed to apply configuration"
        return 1
    fi
}

# Function to verify DNS resolution
verify_dns() {
    log_header "Verifying DNS Resolution"
    
    # Test DNS resolution
    local test_domains=("google.com" "cloudflare.com" "ubuntu.com")
    
    for domain in "${test_domains[@]}"; do
        if timeout 5 nslookup "$domain" >/dev/null 2>&1; then
            log_success "DNS resolution test passed: $domain"
        else
            log_warning "DNS resolution test failed: $domain"
        fi
    done
    
    # Show current DNS servers (filtered to exclude virtual interfaces)
    log_info "Current DNS servers:"
    if command -v systemd-resolve >/dev/null 2>&1; then
        systemd-resolve --status | grep "DNS Servers:" | grep -v -E "(veth|docker|br-|virbr|lxc)" | head -3
    elif command -v resolvectl >/dev/null 2>&1; then
        resolvectl status | grep "DNS Servers:" | grep -v -E "(veth|docker|br-|virbr|lxc)" | head -3
    else
        cat /etc/resolv.conf | grep nameserver
    fi
}

# Function to show current DNS configuration
show_current_dns() {
    log_header "Current DNS Configuration"
    
    echo -e "${YELLOW}Active DNS servers:${NC}"
    if command -v systemd-resolve >/dev/null 2>&1; then
        # Show only global DNS and main interfaces, filter out Docker/virtual interfaces
        systemd-resolve --status | grep -E "(Global|Link [0-9]+ \([^v]|DNS Servers|DNS Domain)" | 
        grep -v -E "(veth|docker|br-|virbr|lxc)"
    elif command -v resolvectl >/dev/null 2>&1; then
        # Show only global DNS and main interfaces, filter out Docker/virtual interfaces  
        resolvectl status | grep -E "(Global|Link [0-9]+ \([^v]|DNS Servers|DNS Domain)" | 
        grep -v -E "(veth|docker|br-|virbr|lxc)"
    else
        echo -e "${BLUE}/etc/resolv.conf content:${NC}"
        cat /etc/resolv.conf | grep -E "(nameserver|domain|search)"
    fi
    
    echo ""
    echo -e "${YELLOW}Physical interfaces DNS summary:${NC}"
    
    # Get physical interfaces only
    local all_interfaces=($(ip link show | awk -F': ' '/^[0-9]+:/ && !/lo:/ {print $2}' | cut -d'@' -f1))
    local phys_interfaces=()
    
    for iface in "${all_interfaces[@]}"; do
        if [[ ! "$iface" =~ ^(docker|br-|veth|virbr|lxc|tun|tap|wg|ppp) ]]; then
            phys_interfaces+=("$iface")
        fi
    done
    
    for iface in "${phys_interfaces[@]}"; do
        local status=$(ip link show "$iface" | grep -o "state [A-Z]*" | cut -d' ' -f2)
        echo -e "  ${CYAN}$iface${NC} (${status})"
        
        # Try to get DNS servers for this interface
        if command -v systemd-resolve >/dev/null 2>&1; then
            local dns_info=$(systemd-resolve --status "$iface" 2>/dev/null | grep "DNS Servers:" | head -1)
            if [[ -n "$dns_info" ]]; then
                echo "    $dns_info"
            else
                echo "    No specific DNS servers configured"
            fi
        elif command -v resolvectl >/dev/null 2>&1; then
            local dns_info=$(resolvectl status "$iface" 2>/dev/null | grep "DNS Servers:" | head -1)
            if [[ -n "$dns_info" ]]; then
                echo "    $dns_info"
            else
                echo "    No specific DNS servers configured"
            fi
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Netplan configuration:${NC}"
    if [[ -f "$NETPLAN_CONFIG" ]]; then
        cat "$NETPLAN_CONFIG"
    else
        echo "No netplan configuration found"
        
        # Show all netplan files if main one doesn't exist
        local netplan_files=($(find "$NETPLAN_DIR" -name "*.yaml" -o -name "*.yml" 2>/dev/null))
        if [[ ${#netplan_files[@]} -gt 0 ]]; then
            echo -e "\n${BLUE}Available netplan files:${NC}"
            for file in "${netplan_files[@]}"; do
                echo "  - $(basename "$file")"
            done
        fi
    fi
}

# Function to restore from backup
restore_backup() {
    log_header "Restoring from Backup"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "No backup directory found"
        exit 1
    fi
    
    local backups=($(find "$BACKUP_DIR" -name "netplan-backup-*.yaml" | sort -r))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        log_error "No backups found"
        exit 1
    fi
    
    echo -e "${YELLOW}Available backups:${NC}"
    for i in "${!backups[@]}"; do
        local backup_date=$(basename "${backups[i]}" .yaml | sed 's/netplan-backup-//')
        echo -e "  ${YELLOW}$((i+1)).${NC} $backup_date"
    done
    
    echo -n "Select backup to restore (1-${#backups[@]}): "
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#backups[@]} ]]; then
        local selected_backup="${backups[$((selection-1))]}"
        
        # Backup current config before restoring
        if [[ -f "$NETPLAN_CONFIG" ]]; then
            cp "$NETPLAN_CONFIG" "$NETPLAN_CONFIG.before-restore"
        fi
        
        # Restore backup
        cp "$selected_backup" "$NETPLAN_CONFIG"
        log_success "Backup restored from: $selected_backup"
        
        # Apply the restored configuration
        apply_config
    else
        log_error "Invalid selection"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo -e "${CYAN}Usage: $SCRIPT_NAME [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  ${GREEN}-h, --help${NC}        Show this help message"
    echo -e "  ${GREEN}-s, --show${NC}        Show current DNS configuration"
    echo -e "  ${GREEN}-r, --restore${NC}     Restore from backup"
    echo -e "  ${GREEN}-p, --provider N${NC}  Set DNS provider directly (1-7)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$SCRIPT_NAME${NC}                 Interactive mode"
    echo -e "  ${GREEN}$SCRIPT_NAME -p 1${NC}            Set Cloudflare DNS"
    echo -e "  ${GREEN}$SCRIPT_NAME --show${NC}          Show current DNS"
    echo -e "  ${GREEN}$SCRIPT_NAME --restore${NC}       Restore backup"
}

# Main function
main() {
    local provider=""
    local show_current=false
    local restore_mode=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -s|--show)
                show_current=true
                shift
                ;;
            -r|--restore)
                restore_mode=true
                shift
                ;;
            -p|--provider)
                provider="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log_header "DNS Configuration Script for Ubuntu Netplan"
    
    # Check system requirements
    check_root
    check_ubuntu
    check_netplan
    
    # Find netplan configuration
    find_netplan_config
    
    # Handle special modes
    if [[ "$show_current" == true ]]; then
        show_current_dns
        exit 0
    fi
    
    if [[ "$restore_mode" == true ]]; then
        restore_backup
        exit 0
    fi
    
    # Detect network interface
    detect_interface
    
    # Get DNS provider
    if [[ -n "$provider" ]]; then
        if ! get_dns_servers "$provider"; then
            exit 1
        fi
    else
        # Interactive mode
        show_dns_providers
        echo -n "Select DNS provider (1-9): "
        read -r choice
        
        case $choice in
            8)
                show_current_dns
                exit 0
                ;;
            9)
                restore_backup
                exit 0
                ;;
            *)
                if ! get_dns_servers "$choice"; then
                    exit 1
                fi
                ;;
        esac
    fi
    
    # Confirm changes
    echo ""
    log_info "Configuration Summary:"
    echo -e "  ${YELLOW}Interface:${NC} $INTERFACE"
    echo -e "  ${YELLOW}DNS Provider:${NC} $DNS_NAME"
    echo -e "  ${YELLOW}DNS Servers:${NC} $(IFS=', '; echo "${DNS_SERVERS[*]}")"
    echo ""
    echo -n "Apply this configuration? (y/N): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Configuration cancelled"
        exit 0
    fi
    
    # Apply configuration
    backup_config
    create_netplan_config
    
    if validate_config; then
        apply_config
        log_success "DNS configuration completed successfully!"
    else
        log_error "Configuration failed validation"
        
        # Restore backup if available
        local latest_backup="$BACKUP_DIR/latest-backup.txt"
        if [[ -f "$latest_backup" ]]; then
            local backup_file=$(cat "$latest_backup")
            if [[ "$backup_file" != "none" ]] && [[ -f "$backup_file" ]]; then
                log_info "Restoring previous configuration..."
                cp "$backup_file" "$NETPLAN_CONFIG"
                netplan apply
                log_info "Previous configuration restored"
            fi
        fi
        exit 1
    fi
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"