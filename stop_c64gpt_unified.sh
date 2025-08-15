#!/bin/bash

# C64GPT Unified Management Interface Stop Script
# Stops the unified C64GPT management interface

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

# Function to check if app is running
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

# Function to stop the app
stop_app() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        
        if ps -p "$pid" > /dev/null 2>&1; then
            print_status "Stopping C64GPT unified management interface (PID: $pid)..."
            
            # Try graceful termination first
            kill "$pid"
            
            # Wait for graceful shutdown
            local count=0
            while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            
            # Force kill if still running
            if ps -p "$pid" > /dev/null 2>&1; then
                print_warning "Graceful shutdown failed, forcing termination..."
                kill -9 "$pid"
                sleep 1
            fi
            
            # Verify it's stopped
            if ps -p "$pid" > /dev/null 2>&1; then
                print_error "Failed to stop C64GPT unified management interface"
                return 1
            else
                print_success "C64GPT unified management interface stopped successfully"
                
                # Log the stop
                echo "$(date): C64GPT unified management interface stopped (PID: $pid)" >> "$LOG_FILE"
                
                # Clean up PID file
                rm -f "$PID_FILE"
                return 0
            fi
        else
            print_warning "Process $pid is not running"
            rm -f "$PID_FILE"
            return 0
        fi
    else
        print_warning "No PID file found - app may not be running"
        return 0
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -f, --force    Force stop (kill -9)"
    echo "  -s, --status   Show status only"
    echo ""
    echo "This script stops the C64GPT unified management interface."
}

# Main execution
main() {
    local force_stop=false
    local status_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--force)
                force_stop=true
                shift
                ;;
            -s|--status)
                status_only=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_highlight "C64GPT Unified Management Interface Stop Script"
    echo ""
    
    # Check status
    if is_app_running; then
        local pid=$(cat "$PID_FILE")
        if [ "$status_only" = true ]; then
            print_status "C64GPT unified management interface is running (PID: $pid)"
            exit 0
        else
            print_status "C64GPT unified management interface is running (PID: $pid)"
        fi
    else
        if [ "$status_only" = true ]; then
            print_status "C64GPT unified management interface is not running"
            exit 0
        else
            print_warning "C64GPT unified management interface is not running"
            exit 0
        fi
    fi
    
    # Stop the app
    if stop_app; then
        print_highlight "C64GPT unified management interface has been stopped"
    else
        print_error "Failed to stop C64GPT unified management interface"
        exit 1
    fi
}

# Run main function
main "$@"
