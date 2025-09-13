# System Setup Scripts

A collection of automated setup scripts for development environments across macOS, Ubuntu, Debian, Arch Linux, Fedora, RHEL, and CentOS.

## 🚀 Quick Start

Install all tools with one command:

```bash
curl -sSL https://raw.githubusercontent.com/matteomelillo/system-scripts/main/quick-install.sh | bash
```

## 📦 What Gets Installed

### Non-Interactive Scripts
- **QEMU Guest Agent** - Enhanced VM integration (QEMU/KVM environments only)
- **Zoxide** - Smart directory navigation (better `cd`)
- **Starship** - Beautiful terminal prompt with Catppuccin theme
- **LazyVim** - Modern Neovim configuration with all dependencies

### Interactive Script
- **DNS Configuration** - Configure DNS servers with netplan (Ubuntu only)

## 🛠️ Individual Scripts

### QEMU Guest Agent
```bash
curl -sSL https://raw.githubusercontent.com/matteomelillo/system-scripts/main/installQemuGuestAgent.sh | bash
```

**Features:**
- Auto-detects virtualization environment
- Only installs in QEMU/KVM VMs
- Enables better VM performance and management
- Supports multiple Linux distributions

### Zoxide Installation
```bash
curl -sSL https://raw.githubusercontent.com/matteomelillo/system-scripts/main/installZoxide.sh | bash
```

**Features:**
- Smart directory navigation
- Replaces `cd` with intelligent jumping
- Shell integration (bash/zsh)
- Works across all supported OS

### Starship Prompt
```bash
curl -sSL https://raw.githubusercontent.com/matteomelillo/system-scripts/main/installStarship.sh | bash
```

**Features:**
- Beautiful terminal prompt
- Catppuccin Powerline theme
- Nerd Font installation
- Multi-shell support

### LazyVim
```bash
curl -sSL https://raw.githubusercontent.com/matteomelillo/system-scripts/main/installLazyVim.sh | bash
```

**Features:**
- Complete Neovim setup
- Modern plugin ecosystem
- LSP servers and build tools
- Backup of existing configuration

### DNS Configuration (Ubuntu)
```bash
curl -sSL https://raw.githubusercontent.com/matteomelillo/system-scripts/main/setDNSNetplan.sh | sudo bash
```

**Features:**
- Interactive DNS provider selection
- Netplan configuration
- Configuration backup and restore
- Multiple DNS provider options (Cloudflare, Google, Quad9, etc.)

## 🖥️ Supported Operating Systems

| OS | Support Level | Notes |
|---|---|---|
| **macOS** | ✅ Full | Via Homebrew when available |
| **Ubuntu** | ✅ Full | All features including DNS config |
| **Debian** | ✅ Full | Package manager support |
| **Arch Linux** | ✅ Full | Pacman and AUR support |
| **Manjaro** | ✅ Full | Same as Arch Linux |
| **Fedora** | ✅ Full | DNF package manager |
| **RHEL/CentOS** | ✅ Good | Limited to available packages |

## 🎯 Use Cases

### Development Environment Setup
Perfect for setting up new development machines with essential tools.

### Server Administration
Ideal for configuring new servers with improved shell experience.

### Virtual Machine Setup
Automatically configures VM-specific optimizations.

### Dotfiles Alternative
Provides a curated set of tools without complex dotfiles management.

## 🔧 Manual Installation

If you prefer to run scripts individually:

1. **Download script:**
   ```bash
   curl -O https://raw.githubusercontent.com/matteomelillo/system-scripts/main/SCRIPT_NAME.sh
   ```

2. **Make executable:**
   ```bash
   chmod +x SCRIPT_NAME.sh
   ```

3. **Run:**
   ```bash
   ./SCRIPT_NAME.sh
   ```

## 🛡️ Safety Features

- **Non-destructive:** All scripts backup existing configurations
- **Error handling:** Robust error checking and recovery
- **OS detection:** Automatic platform-specific installation
- **Dependency checking:** Verifies prerequisites before installation
- **Interrupt handling:** Clean exit on Ctrl+C

## 📋 Prerequisites

### Required (auto-installed if missing):
- `curl` or `wget`
- `git`
- Internet connection

### Optional (enhances functionality):
- Package manager with sudo access
- Terminal with font support for Starship

## 🎨 Customization

### Starship Theme
After installation, customize your prompt:
```bash
nvim ~/.config/starship.toml
```

### Zoxide Behavior
Configure directory jumping:
```bash
# Add to your shell RC file
export _ZO_DATA_DIR="$HOME/.config/zoxide"
```

### LazyVim Configuration
Customize Neovim:
```bash
nvim ~/.config/nvim/lua/config/
```

## 🐛 Troubleshooting

### Permission Issues
```bash
# Make sure you have proper permissions
sudo usermod -aG sudo $USER
```

### Missing Dependencies
```bash
# Update package lists first
sudo apt update  # Ubuntu/Debian
sudo pacman -Sy  # Arch
```

### PATH Issues
```bash
# Restart shell or source RC file
source ~/.bashrc  # or ~/.zshrc
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple OS (if possible)
5. Submit a pull request

## 📝 License

MIT License - feel free to use, modify, and distribute.

## 🙋 Support

If you encounter issues:

1. Check the troubleshooting section
2. Verify your OS is supported
3. Run with verbose output: `bash -x script.sh`
4. Open an issue with system details

---

**Happy coding! 🚀**