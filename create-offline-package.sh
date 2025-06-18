#!/bin/bash

# 🚀 MoonMesh Offline Package Creator
# K4lantar4 - Creates complete offline installation package
# Usage: bash create-offline-package.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Variables
PACKAGE_NAME="moonmesh-offline-complete.tar.gz"
TEMP_DIR=$(mktemp -d)
WORK_DIR="$TEMP_DIR/moonmesh-offline"

# =============================================================================
# Helper Functions
# =============================================================================

log() {
    local color="$1"
    local text="$2"
    case $color in
        red) echo -e "${RED}❌ $text${NC}" ;;
        green) echo -e "${GREEN}✅ $text${NC}" ;;
        yellow) echo -e "${YELLOW}⚠️  $text${NC}" ;;
        cyan) echo -e "${CYAN}🔧 $text${NC}" ;;
        white) echo -e "${WHITE}$text${NC}" ;;
        *) echo -e "$text" ;;
    esac
}

print_header() {
    clear
    echo -e "${CYAN}🚀 MoonMesh Offline Package Creator${NC}"
    echo "=============================================="
    echo -e "${WHITE}Creating complete offline installation package${NC}"
    echo -e "${WHITE}Internet connection required for this step${NC}"
    echo "=============================================="
    echo
}

cleanup() {
    if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# =============================================================================
# System Check
# =============================================================================

check_system() {
    log cyan "Checking system requirements..."
    
    # Check internet connection
    if ! ping -c 1 google.com &> /dev/null; then
        log red "Internet connection required to create offline package"
        exit 1
    fi
    
    # Check required commands
    local missing_commands=()
    for cmd in curl wget tar; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log red "Missing required commands: ${missing_commands[*]}"
        log yellow "Please install: sudo apt-get install ${missing_commands[*]}"
        exit 1
    fi
    
    # Check architecture
    local arch=$(uname -m)
    case $arch in
        x86_64) EASYTIER_ARCH="x86_64" ;;
        aarch64|arm64) EASYTIER_ARCH="aarch64" ;;
        armv7l) EASYTIER_ARCH="armv7" ;;
        *) 
            log red "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    log green "System check passed (Architecture: $EASYTIER_ARCH)"
}

# =============================================================================
# Download EasyTier
# =============================================================================

download_easytier() {
    log cyan "Downloading EasyTier binaries..."
    
    # Create EasyTier directory
    mkdir -p "$WORK_DIR/easytier"
    cd "$WORK_DIR/easytier"
    
    # Get latest release info
    local latest_url="https://api.github.com/repos/EasyTier/EasyTier/releases/latest"
    local release_info=$(curl -s "$latest_url")
    
    if [[ -z "$release_info" ]]; then
        log red "Failed to get EasyTier release information"
        exit 1
    fi
    
    # Extract download URL for our architecture
    local download_url=$(echo "$release_info" | grep -o "https://github.com/EasyTier/EasyTier/releases/download/[^\"]*${EASYTIER_ARCH}[^\"]*\.zip" | head -1)
    
    if [[ -z "$download_url" ]]; then
        log red "No EasyTier release found for architecture: $EASYTIER_ARCH"
        exit 1
    fi
    
    local version=$(echo "$release_info" | grep '"tag_name"' | cut -d'"' -f4)
    log cyan "Downloading EasyTier $version for $EASYTIER_ARCH..."
    
    # Download and extract
    if wget -q "$download_url" -O easytier.zip; then
        log green "EasyTier downloaded successfully"
    else
        log red "Failed to download EasyTier"
        exit 1
    fi
    
    # Extract binaries
    if command -v unzip &> /dev/null; then
        unzip -q easytier.zip
        rm easytier.zip
        
        # Find and move binaries
        find . -name "easytier-core" -executable -exec mv {} . \;
        find . -name "easytier-cli" -executable -exec mv {} . \;
        
        # Clean up extracted directories
        find . -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
        
        if [[ -f "easytier-core" ]] && [[ -f "easytier-cli" ]]; then
            chmod +x easytier-core easytier-cli
            log green "EasyTier binaries extracted successfully"
        else
            log red "EasyTier binaries not found after extraction"
            exit 1
        fi
    else
        log red "unzip command not found. Please install unzip package."
        exit 1
    fi
}

# =============================================================================
# Download HAProxy Packages
# =============================================================================

download_haproxy_packages() {
    log cyan "Downloading HAProxy packages..."
    
    # Create HAProxy packages directory
    mkdir -p "$WORK_DIR/haproxy-packages"
    cd "$WORK_DIR/haproxy-packages"
    
    # Detect Ubuntu/Debian version
    local distro=""
    local version=""
    
    if [[ -f "/etc/os-release" ]]; then
        source /etc/os-release
        distro="$ID"
        version="$VERSION_CODENAME"
    fi
    
    if [[ -z "$version" ]]; then
        # Default to Ubuntu 20.04 packages
        version="focal"
        log yellow "Could not detect OS version, using Ubuntu 20.04 packages"
    fi
    
    log cyan "Detected: $distro $version"
    
    # Download HAProxy and dependencies
    local packages=(
        "haproxy"
        "libssl1.1"
        "libpcre3"
        "liblua5.3-0"
    )
    
    for package in "${packages[@]}"; do
        log cyan "Downloading $package..."
        
        if apt-get download "$package" 2>/dev/null; then
            log green "$package downloaded"
        else
            log yellow "Could not download $package (may not be needed)"
        fi
    done
    
    # Count downloaded packages
    local package_count=$(ls *.deb 2>/dev/null | wc -l)
    if [[ $package_count -gt 0 ]]; then
        log green "Downloaded $package_count HAProxy packages"
    else
        log yellow "No HAProxy packages downloaded"
    fi
}

# =============================================================================
# Copy MoonMesh Files
# =============================================================================

copy_moonmesh_files() {
    log cyan "Copying MoonMesh files..."
    
    # Store original directory
    local original_dir=$(pwd)
    cd "$WORK_DIR"
    
    # Copy main files from original directory
    local files_to_copy=(
        "moonmesh.sh"
        "install.sh"
        "LICENSE"
        "README.md"
    )
    
    for file in "${files_to_copy[@]}"; do
        if [[ -f "$original_dir/$file" ]]; then
            cp "$original_dir/$file" . 2>/dev/null || {
                log yellow "Could not copy $file"
            }
        fi
    done
    
    # Verify critical files
    if [[ ! -f "moonmesh.sh" ]]; then
        log red "moonmesh.sh not found. Make sure moonmesh.sh exists in the source directory."
        exit 1
    fi
    
    log green "MoonMesh files copied successfully"
}

# =============================================================================
# Create Package
# =============================================================================

create_package() {
    log cyan "Creating offline package..."
    
    cd "$TEMP_DIR"
    
    # Create package info
    cat > "$WORK_DIR/PACKAGE_INFO.txt" << EOF
MoonMesh Offline Package
========================

Created: $(date)
Architecture: $EASYTIER_ARCH
Creator: MoonMesh Package Creator

Contents:
- EasyTier Core & CLI
- MoonMesh Manager
- HAProxy Packages (if available)
- Installation Scripts

Installation:
1. Extract this package
2. Run: sudo bash offline-install.sh

For more information, see README.md
EOF
    
    # Create archive
    if tar -czf "$PACKAGE_NAME" moonmesh-offline/; then
        log green "Package created successfully"
    else
        log red "Failed to create package"
        exit 1
    fi
    
    # Move to current directory
    mv "$PACKAGE_NAME" "$(pwd)/../"
    cd ..
    
    # Show package info
    local package_size=$(du -h "$PACKAGE_NAME" | cut -f1)
    log green "Package size: $package_size"
    
    # Show contents summary
    echo
    log cyan "Package contents summary:"
    tar -tzf "$PACKAGE_NAME" | head -20
    if [[ $(tar -tzf "$PACKAGE_NAME" | wc -l) -gt 20 ]]; then
        echo "... and more files"
    fi
}

# =============================================================================
# Show Summary
# =============================================================================

show_summary() {
    echo
    log green "🎉 Offline Package Created Successfully!"
    echo
    echo -e "${CYAN}📦 Package Details:${NC}"
    echo "  📁 File: $PACKAGE_NAME"
    echo "  📏 Size: $(du -h "$PACKAGE_NAME" | cut -f1)"
    echo "  🏗️  Architecture: $EASYTIER_ARCH"
    echo "  📅 Created: $(date)"
    echo
    echo -e "${GREEN}🚀 Usage Instructions:${NC}"
    echo "  1. Copy $PACKAGE_NAME to target server"
    echo "  2. Copy offline-install.sh to target server"
    echo "  3. Run: sudo bash offline-install.sh"
    echo
    echo -e "${YELLOW}💡 Transfer Methods:${NC}"
    echo "  • SCP: scp $PACKAGE_NAME user@server:/path/"
    echo "  • USB: Copy both files to USB drive"
    echo "  • SFTP: Use SFTP client to transfer files"
    echo
    log green "Ready for offline installation! 🚀"
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    # Set cleanup trap
    trap cleanup EXIT
    
    print_header
    
    log cyan "Starting package creation process..."
    echo
    
    # Package creation steps
    check_system
    download_easytier
    download_haproxy_packages
    copy_moonmesh_files
    create_package
    show_summary
    
    echo
    log green "Package creation completed successfully! ⚡"
}

# Run main function
main "$@" 