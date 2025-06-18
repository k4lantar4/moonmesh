#!/bin/bash

# 🚀 MoonMesh Complete Offline Installer
# K4lantar4 - For servers without internet connection
# Usage: sudo bash offline-install.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Variables
ARCHIVE_NAME="moonmesh-offline-complete.tar.gz"
DEST_DIR="/usr/local/bin"
CURRENT_DIR=$(pwd)

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
    echo -e "${CYAN}🚀 MoonMesh Complete Offline Installer${NC}"
    echo "=============================================="
    echo -e "${WHITE}EasyTier + HAProxy + MoonMesh Manager${NC}"
    echo -e "${WHITE}No Internet Required - Complete Package${NC}"
    echo "=============================================="
    echo
}

# =============================================================================
# System Preparation
# =============================================================================

check_requirements() {
    log cyan "Checking system requirements..."
    
    # Check root access
    if [[ $EUID -ne 0 ]]; then
        log red "Root access required. Usage: sudo $0"
        exit 1
    fi
    
    # Check archive exists
    if [[ ! -f "$ARCHIVE_NAME" ]]; then
        log red "Archive not found: $ARCHIVE_NAME"
        echo
        log yellow "Expected files in current directory:"
        echo "  • $ARCHIVE_NAME"
        echo "  • $0 (this script)"
        echo
        log yellow "Make sure both files are in the same directory!"
        exit 1
    fi
    
    # Check tar command
    if ! command -v tar &> /dev/null; then
        log red "tar command not found. Please install tar package."
        exit 1
    fi
    
    log green "System requirements satisfied"
}

# =============================================================================
# Archive Extraction
# =============================================================================

extract_archive() {
    log cyan "Extracting offline package..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Extract archive
    if tar -xzf "$CURRENT_DIR/$ARCHIVE_NAME"; then
        log green "Archive extracted successfully"
    else
        log red "Failed to extract archive"
        exit 1
    fi
    
    # Verify contents
    if [[ ! -f "moonmesh.sh" ]] || [[ ! -f "install.sh" ]] || [[ ! -d "easytier" ]] || [[ ! -d "haproxy-packages" ]]; then
        log red "Archive contents verification failed"
        log yellow "Missing required files or directories"
        exit 1
    fi
    
    log green "Archive contents verified"
    
    # Return to temp directory for installation
    export TEMP_INSTALL_DIR="$temp_dir"
}

# =============================================================================
# EasyTier Installation
# =============================================================================

install_easytier_offline() {
    log cyan "Installing EasyTier from local files..."
    
    cd "$TEMP_INSTALL_DIR"
    
    # Check EasyTier binaries
    if [[ ! -f "easytier/easytier-core" ]] || [[ ! -f "easytier/easytier-cli" ]]; then
        log red "EasyTier binaries not found"
        exit 1
    fi
    
    # Make executable
    chmod +x easytier/easytier-core easytier/easytier-cli
    
    # Install to system
    cp easytier/easytier-core "$DEST_DIR/" || {
        log red "Failed to install easytier-core"
        exit 1
    }
    
    cp easytier/easytier-cli "$DEST_DIR/" || {
        log red "Failed to install easytier-cli"
        exit 1
    }
    
    # Install MoonMesh manager
    cp moonmesh.sh "$DEST_DIR/moonmesh" || {
        log red "Failed to install moonmesh manager"
        exit 1
    }
    chmod +x "$DEST_DIR/moonmesh"
    
    # Create config directory
    mkdir -p /etc/easytier
    
    log green "EasyTier installed successfully"
}

# =============================================================================
# HAProxy Installation
# =============================================================================

install_haproxy_offline() {
    log cyan "Installing HAProxy from local packages..."
    
    cd "$TEMP_INSTALL_DIR"
    
    # Check packages directory
    if [[ ! -d "haproxy-packages" ]]; then
        log yellow "HAProxy packages directory not found, skipping HAProxy installation"
        return 0
    fi
    
    # Count packages
    local package_count=$(ls haproxy-packages/*.deb 2>/dev/null | wc -l)
    if [[ $package_count -eq 0 ]]; then
        log yellow "No .deb packages found, skipping HAProxy installation"
        return 0
    fi
    
    log cyan "Found $package_count HAProxy packages"
    
    # Install packages
    if dpkg -i haproxy-packages/*.deb 2>/dev/null; then
        log green "HAProxy packages installed successfully"
    else
        log yellow "Some dependency issues detected, attempting to fix..."
        
        # Try to fix dependencies
        if apt-get install -f -y 2>/dev/null; then
            log green "Dependencies fixed successfully"
        else
            log yellow "Could not fix all dependencies automatically"
            log yellow "HAProxy may need manual dependency resolution"
        fi
    fi
    
    # Verify installation
    if command -v haproxy &> /dev/null; then
        log green "HAProxy installation verified"
        haproxy -v | head -1
    else
        log yellow "HAProxy installation could not be verified"
    fi
}

# =============================================================================
# Final Setup
# =============================================================================

finalize_installation() {
    log cyan "Finalizing installation..."
    
    # Verify EasyTier installation
    if command -v easytier-core &> /dev/null && command -v easytier-cli &> /dev/null; then
        log green "EasyTier installation verified"
    else
        log red "EasyTier installation verification failed"
        exit 1
    fi
    
    # Verify MoonMesh manager
    if [[ -x "$DEST_DIR/moonmesh" ]]; then
        log green "MoonMesh manager installation verified"
    else
        log red "MoonMesh manager installation verification failed"
        exit 1
    fi
    
    # Cleanup
    if [[ -n "$TEMP_INSTALL_DIR" ]] && [[ -d "$TEMP_INSTALL_DIR" ]]; then
        cd "$CURRENT_DIR"
        rm -rf "$TEMP_INSTALL_DIR"
        log green "Temporary files cleaned up"
    fi
    
    log green "Installation finalized successfully"
}

# =============================================================================
# Installation Summary
# =============================================================================

show_installation_summary() {
    echo
    log green "🎉 MoonMesh Offline Installation Completed!"
    echo
    echo -e "${CYAN}📦 Installed Components:${NC}"
    echo "  ✅ EasyTier Core & CLI"
    echo "  ✅ MoonMesh Manager"
    if command -v haproxy &> /dev/null; then
        echo "  ✅ HAProxy Load Balancer"
    else
        echo "  ⚠️  HAProxy (installation issues)"
    fi
    echo
    echo -e "${GREEN}🚀 Quick Start:${NC}"
    echo "  sudo moonmesh"
    echo
    echo -e "${CYAN}📖 Manual Usage:${NC}"
    echo "  sudo easytier-core --help"
    echo "  sudo easytier-cli --help"
    if command -v haproxy &> /dev/null; then
        echo "  sudo haproxy -v"
    fi
    echo
    echo -e "${YELLOW}💡 Next Steps:${NC}"
    echo "  1. Run 'sudo moonmesh' to start configuration"
    echo "  2. Use 'Quick Connect' to create your mesh network"
    echo "  3. Configure HAProxy load balancer if needed"
    echo
    log green "Ready to create your mesh network! 🚀"
}

# =============================================================================
# Main Installation Process
# =============================================================================

main() {
    print_header
    
    log cyan "Starting offline installation process..."
    echo
    
    # Installation steps
    check_requirements
    extract_archive
    install_easytier_offline
    install_haproxy_offline
    finalize_installation
    show_installation_summary
    
    echo
    log green "Installation completed successfully! ⚡"
    echo
    log cyan "Archive used: $ARCHIVE_NAME ($(du -h "$CURRENT_DIR/$ARCHIVE_NAME" | cut -f1))"
}

# Run main function
main "$@"