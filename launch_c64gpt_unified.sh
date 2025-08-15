#!/bin/bash

# C64GPT Unified Management Interface Launcher
# Builds and launches the unified C64GPT management interface

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
APP_NAME="PetsponderApp"
PID_FILE="$PROJECT_ROOT/c64gpt_unified.pid"
LOG_FILE="$PROJECT_ROOT/c64gpt_unified.log"

# Function to print colored output
print_status() {
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

print_highlight() {
    echo -e "${PURPLE}[C64GPT UNIFIED]${NC} $1"
}

# Function to check if app is already running
is_app_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # App is running
        else
            # PID file exists but process is dead
            rm -f "$PID_FILE"
        fi
    fi
    return 1  # App is not running
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check if Swift is available
    if ! command -v swift >/dev/null 2>&1; then
        print_error "Swift is not installed or not in PATH"
        exit 1
    fi
    
    # Check if Xcode command line tools are available (for macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! xcode-select -p >/dev/null 2>&1; then
            print_warning "Xcode command line tools not found"
            print_status "You may need to install them with: xcode-select --install"
        fi
    fi
    
    # Check if jq is available for config validation
    if ! command -v jq >/dev/null 2>&1; then
        print_warning "jq not found - configuration validation will be skipped"
    fi
    
    print_success "Dependencies check completed"
}

# Function to validate configuration
validate_config() {
    local config_file="$PROJECT_ROOT/Config/config.json"
    
    if [ ! -f "$config_file" ]; then
        print_warning "Configuration file not found at $config_file"
        print_status "Using default configuration"
        return 0
    fi
    
    # Basic JSON validation
    if ! jq empty "$config_file" 2>/dev/null; then
        print_error "Invalid JSON in configuration file"
        return 1
    fi
    
    # Validate required fields
    local telnet_port=$(jq -r '.telnetPort // 6400' "$config_file")
    local width=$(jq -r '.width // 40' "$config_file")
    local default_model=$(jq -r '.defaultModel // "gemma2:2b"' "$config_file")
    
    if [ "$telnet_port" -lt 1 ] || [ "$telnet_port" -gt 65535 ]; then
        print_error "Invalid telnet port: $telnet_port (must be 1-65535)"
        return 1
    fi
    
    if [ "$width" -lt 10 ] || [ "$width" -gt 200 ]; then
        print_error "Invalid width: $width (must be 10-200)"
        return 1
    fi
    
    print_success "Configuration validated successfully"
    print_status "Telnet port: $telnet_port"
    print_status "Terminal width: $width"
    print_status "Default model: $default_model"
    return 0
}

# Function to build the app
build_app() {
    print_highlight "Building C64GPT unified management interface..."
    
    # Change to project directory
    cd "$PROJECT_ROOT"
    
    # Clean previous build
    print_status "Cleaning previous build..."
    swift package clean
    
    # Build the app
    swift build --product PetsponderApp -c release
    
    print_success "App build completed"
}

# Function to launch the app
launch_app() {
    print_highlight "Launching C64GPT unified management interface..."
    
    # Change to project directory
    cd "$PROJECT_ROOT"
    
    # Launch the app
    swift run PetsponderApp &
    local app_pid=$!
    
    # Save PID
    echo "$app_pid" > "$PID_FILE"
    
    # Wait a moment to check if it started successfully
    sleep 2
    
    if ps -p "$app_pid" > /dev/null 2>&1; then
        print_success "C64GPT unified management interface launched successfully!"
        print_status "Process ID: $app_pid"
        print_status "PID file: $PID_FILE"
        
        # Log the launch
        echo "$(date): C64GPT unified management interface launched (PID: $app_pid)" >> "$LOG_FILE"
        
        print_highlight "The unified management interface is now running!"
        print_status "You can manage both the server and LLM models from this interface."
        print_status "To stop the interface, run: ./stop_c64gpt_unified.sh"
        
    else
        print_error "Failed to launch C64GPT unified management interface"
        rm -f "$PID_FILE"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -f, --force    Force launch even if already running"
    echo "  -b, --build    Build only (don't launch)"
    echo "  -v, --validate Validate configuration only"
    echo ""
    echo "This script builds and launches the C64GPT unified management interface"
    echo "which provides a single interface for managing both the server and LLM models."
}

# Main execution
main() {
    local force_launch=false
    local build_only=false
    local validate_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--force)
                force_launch=true
                shift
                ;;
            -b|--build)
                build_only=true
                shift
                ;;
            -v|--validate)
                validate_only=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_highlight "C64GPT Unified Management Interface Launcher"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Validate configuration
    if ! validate_config; then
        print_error "Configuration validation failed"
        exit 1
    fi
    
    if [ "$validate_only" = true ]; then
        print_success "Configuration validation completed successfully"
        exit 0
    fi
    
    # Check if already running
    if is_app_running && [ "$force_launch" = false ]; then
        local pid=$(cat "$PID_FILE")
        print_warning "C64GPT unified management interface is already running (PID: $pid)"
        print_status "Use -f or --force to launch anyway"
        exit 1
    fi
    
    # Build the app
    build_app
    
    if [ "$build_only" = true ]; then
        print_success "Build completed successfully"
        exit 0
    fi
    
    # Launch the app
    launch_app
}

# Run main function
main "$@"
