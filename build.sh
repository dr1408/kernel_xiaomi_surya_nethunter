#!/bin/bash
#
# Automatic PixelOS Kernel Build Script
# For surya with AOSP Clang toolchain

# Timer
SECONDS=0

# Configuration - ALL PATHS RELATIVE TO KERNEL DIR
KERNEL_DIR="$(pwd)"
TOOLCHAIN_DIR="$KERNEL_DIR/toolchains"  # toolchains inside kernel directory

# Toolchain paths - USING STANDARD GNU GCC (Kali compatible)
CLANG_PATH="$TOOLCHAIN_DIR/bin"

# Set environment
export ARCH=arm64
export SUBARCH=arm64
export CLANG_PATH="$CLANG_PATH"
export CROSS_COMPILE="aarch64-linux-gnu-"
export CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
export PATH="$CLANG_PATH:$PATH"

# KBUILD exports - Customize these as you like!
export KBUILD_BUILD_USER="dr1408-Hunter"
export KBUILD_BUILD_HOST="root"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_toolchain() {
    print_info "Checking toolchains..."
    
    if [ ! -f "$CLANG_PATH/clang" ]; then
        print_error "Clang not found at $CLANG_PATH/clang"
        print_info "Expected path: $CLANG_PATH/clang"
        return 1
    fi
    
    # Check if GCC cross-compilers are available in PATH
    if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
        print_error "GCC cross-compiler not found: aarch64-linux-gnu-gcc"
        print_info "Install with: sudo apt install gcc-aarch64-linux-gnu"
        return 1
    fi
    
    print_success "Toolchains verified successfully"
    return 0
}

build_kernel() {
    print_info "Starting kernel build..."
    
    # Clean previous build if requested
    if [ "$1" = "clean" ]; then
        print_info "Cleaning previous build..."
        rm -rf out
    fi
    
    # Create output directory
    mkdir -p out
    
    # Use nethunter_defconfig
    DEFCONFIG="nethunter_defconfig"
    print_info "Using defconfig: $DEFCONFIG"
    
    # Set up defconfig
    print_info "Configuring kernel..."
    make O=out $DEFCONFIG
    
    # Build kernel with -j2
    print_info "Building kernel with -j2..."
    make -j2 O=out \
        CC=clang \
        LD=ld.lld \
        AR=llvm-ar \
        NM=llvm-nm \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        STRIP=llvm-strip \
        Image.gz
    
    # Check if kernel was built
    kernel="out/arch/arm64/boot/Image.gz"
    if [ -f "$kernel" ]; then
        print_success "Kernel compiled successfully!"
        
        # Build modules if any are configured as modules
        if grep "=m" out/.config > /dev/null; then
            print_info "Configuration with modules detected -- building modules with -j1"
            make -j1 O=out \
                CC=clang \
                LD=ld.lld \
                AR=llvm-ar \
                NM=llvm-nm \
                OBJCOPY=llvm-objcopy \
                OBJDUMP=llvm-objdump \
                STRIP=llvm-strip \
                modules
            
            # Find and display the built modules
            print_info "Built modules:"
            find out -name "*.ko" | while read module; do
                print_info "  $(basename $module)"
            done
        else
            print_info "No modules detected in configuration"
        fi
        
        return 0
    else
        print_error "Kernel compilation failed!"
        return 1
    fi
}

# Main execution
echo "=========================================="
echo -e "${GREEN}PixelOS Kernel Build Script${NC}"
echo "=========================================="

# Check toolchains
check_toolchain || exit 1

# Build kernel
build_kernel $1 || exit 1

# Display build time
echo "=========================================="
print_success "Build completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)"
print_info "Kernel image: out/arch/arm64/boot/Image.gz"
echo "=========================================="
