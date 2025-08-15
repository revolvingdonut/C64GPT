#!/bin/bash

# C64GPT Server Management Script
# Enhanced version with configuration validation and monitoring

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
CONFIG_FILE="$PROJECT_ROOT/Config/config.json"
LOG_FILE="$PROJECT_ROOT/c64gpt.log"
PID_FILE="$PROJECT_ROOT/c64gpt.pid"

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

# Function to check if server is already running
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

# Function to validate configuration
validate_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "Configuration file not found at $CONFIG_FILE"
        print_status "Using default configuration"
        return 0
    fi
    
    # Basic JSON validation
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        print_error "Invalid JSON in configuration file"
        return 1
    fi
    
    # Validate required fields
    local telnet_port=$(jq -r '.telnetPort // 6400' "$CONFIG_FILE")
    local width=$(jq -r '.width // 40' "$CONFIG_FILE")
    
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
    return 0
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check if Swift is available
    if ! command -v swift >/dev/null 2>&1; then
        print_error "Swift is not installed or not in PATH"
        exit 1
    fi
    
    # Check if jq is available for config validation
    if ! command -v jq >/dev/null 2>&1; then
        print_warning "jq not found - configuration validation will be skipped"
    fi
    
    # Check if netcat is available for port testing
    if ! command -v nc >/dev/null 2>&1; then
        print_warning "netcat not found - port availability check will be skipped"
    fi
    
    print_success "Dependencies check completed"
}

# Function to check port availability
check_port_availability() {
    local port=$(jq -r '.telnetPort // 6400' "$CONFIG_FILE" 2>/dev/null || echo "6400")
    
    if command -v nc >/dev/null 2>&1; then
        if nc -z localhost "$port" 2>/dev/null; then
            print_warning "Port $port is already in use"
            print_status "This might indicate another C64GPT server is running"
        else
            print_success "Port $port is available"
        fi
    fi
}

# Function to stop existing server
stop_existing_server() {
    if is_server_running; then
        print_status "Stopping existing C64GPT server..."
        
        local pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null || true
        
        # Wait for graceful shutdown
        local count=0
        while [ $count -lt 10 ] && ps -p "$pid" > /dev/null 2>&1; do
            sleep 1
            count=$((count + 1))
        done
        
        # Force kill if still running
        if ps -p "$pid" > /dev/null 2>&1; then
            print_warning "Force killing server process..."
            kill -9 "$pid" 2>/dev/null || true
        fi
        
        rm -f "$PID_FILE"
        print_success "Existing server stopped"
    else
        print_status "No existing server found"
    fi
}

# Function to start the server
start_server() {
    print_status "Starting C64GPT Telnet Server..."
    
    # Change to project directory
    cd "$PROJECT_ROOT"
    
    # Start server in background and capture PID
    nohup swift run "$DAEMON_NAME" > "$LOG_FILE" 2>&1 &
    local server_pid=$!
    
    # Save PID to file
    echo "$server_pid" > "$PID_FILE"
    
    print_status "Server started with PID: $server_pid"
    print_status "Log file: $LOG_FILE"
    
    # Wait a moment for server to initialize
    sleep 3
    
    # Check if server is still running
    if ! ps -p "$server_pid" > /dev/null 2>&1; then
        print_error "Server failed to start"
        print_status "Check log file for details: $LOG_FILE"
        rm -f "$PID_FILE"
        exit 1
    fi
    
    # Get configuration for display
    local telnet_port=$(jq -r '.telnetPort // 6400' "$CONFIG_FILE" 2>/dev/null || echo "6400")
    local width=$(jq -r '.width // 40' "$CONFIG_FILE" 2>/dev/null || echo "40")
    
    print_success "C64GPT Server is running!"
    echo ""
    echo "📡 Connection Information:"
    echo "   Telnet: telnet localhost $telnet_port"
    echo "   Netcat: nc localhost $telnet_port"
    echo ""
    echo "⚙️  Configuration:"
    echo "   Terminal width: $width characters"
    echo "   Log file: $LOG_FILE"
    echo "   PID file: $PID_FILE"
    echo ""
    echo "🛑 To stop the server: ./stop_server.sh"
    echo "📊 To view logs: tail -f $LOG_FILE"
}

# Main execution
main() {
    echo "🚀 C64GPT Server Startup Script"
    echo "================================"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Validate configuration
    if ! validate_config; then
        print_error "Configuration validation failed"
        exit 1
    fi
    
    # Check port availability
    check_port_availability
    
    # Stop existing server
    stop_existing_server
    
    # Start server
    start_server
}

# Run main function
main "$@"
