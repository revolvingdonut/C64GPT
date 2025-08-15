#!/bin/bash

# C64GPT Server Stop Script
# Enhanced version with graceful shutdown and status reporting

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
DAEMON_NAME="PetsponderDaemon"
PID_FILE="$PROJECT_ROOT/c64gpt.pid"
LOG_FILE="$PROJECT_ROOT/c64gpt.log"

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

# Function to check if server is running
is_server_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # Server is running
        else
            # PID file exists but process is dead
            rm -f "$PID_FILE"
        fi
    fi
    return 1  # Server is not running
}

# Function to get server status
get_server_status() {
    if is_server_running; then
        local pid=$(cat "$PID_FILE")
        local uptime=$(ps -o etime= -p "$pid" 2>/dev/null || echo "unknown")
        local memory=$(ps -o rss= -p "$pid" 2>/dev/null || echo "unknown")
        
        echo "Server Status:"
        echo "  PID: $pid"
        echo "  Uptime: $uptime"
        echo "  Memory: ${memory}KB"
        return 0
    else
        echo "Server Status: Not running"
        return 1
    fi
}

# Function to stop server gracefully
stop_server_gracefully() {
    local pid=$(cat "$PID_FILE")
    
    print_status "Sending SIGTERM to server (PID: $pid)..."
    kill "$pid" 2>/dev/null || true
    
    # Wait for graceful shutdown
    local count=0
    local max_wait=30  # Maximum 30 seconds
    
    while [ $count -lt $max_wait ] && ps -p "$pid" > /dev/null 2>&1; do
        sleep 1
        count=$((count + 1))
        
        # Show progress every 5 seconds
        if [ $((count % 5)) -eq 0 ]; then
            print_status "Waiting for graceful shutdown... ($count/$max_wait seconds)"
        fi
    done
    
    # Check if process is still running
    if ps -p "$pid" > /dev/null 2>&1; then
        print_warning "Server did not shut down gracefully"
        return 1
    else
        print_success "Server stopped gracefully"
        return 0
    fi
}

# Function to force kill server
force_kill_server() {
    local pid=$(cat "$PID_FILE")
    
    print_warning "Force killing server process (PID: $pid)..."
    kill -9 "$pid" 2>/dev/null || true
    
    # Wait a moment and check
    sleep 2
    if ps -p "$pid" > /dev/null 2>&1; then
        print_error "Failed to force kill server process"
        return 1
    else
        print_success "Server force killed"
        return 0
    fi
}

# Function to cleanup orphaned processes
cleanup_orphaned_processes() {
    print_status "Checking for orphaned C64GPT processes..."
    
    local orphaned_pids=$(pgrep -f "$DAEMON_NAME" 2>/dev/null || true)
    
    if [ -n "$orphaned_pids" ]; then
        print_warning "Found orphaned processes: $orphaned_pids"
        
        for pid in $orphaned_pids; do
            if [ ! -f "$PID_FILE" ] || [ "$(cat "$PID_FILE" 2>/dev/null)" != "$pid" ]; then
                print_status "Killing orphaned process: $pid"
                kill "$pid" 2>/dev/null || true
            fi
        done
        
        # Force kill any remaining processes
        sleep 2
        local remaining_pids=$(pgrep -f "$DAEMON_NAME" 2>/dev/null || true)
        if [ -n "$remaining_pids" ]; then
            print_warning "Force killing remaining processes: $remaining_pids"
            echo "$remaining_pids" | xargs kill -9 2>/dev/null || true
        fi
    else
        print_success "No orphaned processes found"
    fi
}

# Function to cleanup files
cleanup_files() {
    print_status "Cleaning up server files..."
    
    # Remove PID file
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
        print_status "Removed PID file: $PID_FILE"
    fi
    
    # Optionally rotate log file
    if [ -f "$LOG_FILE" ]; then
        local log_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$log_size" -gt 10485760 ]; then  # 10MB
            print_status "Log file is large ($log_size bytes), consider rotating: $LOG_FILE"
        fi
    fi
}

# Function to show connection status
show_connection_status() {
    # Try to get port from config
    local port=$(jq -r '.telnetPort // 6400' "$PROJECT_ROOT/Config/config.json" 2>/dev/null || echo "6400")
    
    if command -v nc >/dev/null 2>&1; then
        if nc -z localhost "$port" 2>/dev/null; then
            print_warning "Port $port is still in use"
            print_status "This might indicate another service is using the port"
        else
            print_success "Port $port is now available"
        fi
    fi
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --force     Force kill the server"
    echo "  -s, --status    Show server status only"
    echo "  -c, --cleanup   Clean up orphaned processes"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              Stop server gracefully"
    echo "  $0 --force      Force kill server"
    echo "  $0 --status     Show server status"
    echo "  $0 --cleanup    Clean up orphaned processes"
}

# Main execution
main() {
    local force_kill=false
    local status_only=false
    local cleanup_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                force_kill=true
                shift
                ;;
            -s|--status)
                status_only=true
                shift
                ;;
            -c|--cleanup)
                cleanup_only=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "🛑 C64GPT Server Stop Script"
    echo "============================"
    echo ""
    
    # Show status only
    if [ "$status_only" = true ]; then
        get_server_status
        exit 0
    fi
    
    # Cleanup only
    if [ "$cleanup_only" = true ]; then
        cleanup_orphaned_processes
        cleanup_files
        exit 0
    fi
    
    # Check if server is running
    if ! is_server_running; then
        print_warning "C64GPT server is not running"
        
        # Still cleanup orphaned processes
        cleanup_orphaned_processes
        cleanup_files
        show_connection_status
        exit 0
    fi
    
    # Show current status
    print_status "Current server status:"
    get_server_status
    echo ""
    
    # Stop server
    if [ "$force_kill" = true ]; then
        force_kill_server
    else
        if ! stop_server_gracefully; then
            print_warning "Graceful shutdown failed, attempting force kill..."
            force_kill_server
        fi
    fi
    
    # Cleanup
    cleanup_orphaned_processes
    cleanup_files
    
    # Show final status
    echo ""
    show_connection_status
    
    print_success "C64GPT server stopped successfully"
}

# Run main function
main "$@"
