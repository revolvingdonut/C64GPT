#!/bin/bash

# C64GPT Server Status Script
# Quick status check and monitoring

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
CONFIG_FILE="$PROJECT_ROOT/Config/config.json"

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

# Function to get server details
get_server_details() {
    if is_server_running; then
        local pid=$(cat "$PID_FILE")
        local uptime=$(ps -o etime= -p "$pid" 2>/dev/null || echo "unknown")
        local memory=$(ps -o rss= -p "$pid" 2>/dev/null || echo "unknown")
        local cpu=$(ps -o %cpu= -p "$pid" 2>/dev/null || echo "unknown")
        
        echo "🟢 Server Status: RUNNING"
        echo "  PID: $pid"
        echo "  Uptime: $uptime"
        echo "  Memory: ${memory}KB"
        echo "  CPU: ${cpu}%"
        return 0
    else
        echo "🔴 Server Status: STOPPED"
        return 1
    fi
}

# Function to get configuration info
get_config_info() {
    if [ -f "$CONFIG_FILE" ]; then
        local telnet_port=$(jq -r '.telnetPort // 6400' "$CONFIG_FILE" 2>/dev/null || echo "6400")
        local width=$(jq -r '.width // 40' "$CONFIG_FILE" 2>/dev/null || echo "40")
        local model=$(jq -r '.defaultModel // "gemma2:2b"' "$CONFIG_FILE" 2>/dev/null || echo "gemma2:2b")
        local log_level=$(jq -r '.logLevel // "info"' "$CONFIG_FILE" 2>/dev/null || echo "info")
        
        echo "⚙️  Configuration:"
        echo "  Telnet Port: $telnet_port"
        echo "  Terminal Width: $width"
        echo "  Default Model: $model"
        echo "  Log Level: $log_level"
    else
        echo "⚙️  Configuration: Using defaults (no config file found)"
    fi
}

# Function to check port status
check_port_status() {
    local port=$(jq -r '.telnetPort // 6400' "$CONFIG_FILE" 2>/dev/null || echo "6400")
    
    if command -v nc >/dev/null 2>&1; then
        if nc -z localhost "$port" 2>/dev/null; then
            echo "🔌 Port Status: $port is LISTENING"
        else
            echo "🔌 Port Status: $port is NOT LISTENING"
        fi
    else
        echo "🔌 Port Status: Unable to check (netcat not available)"
    fi
}

# Function to show recent logs
show_recent_logs() {
    if [ -f "$LOG_FILE" ]; then
        local log_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || echo "0")
        local line_count=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
        
        echo "📊 Log File: $LOG_FILE"
        echo "  Size: $log_size bytes"
        echo "  Lines: $line_count"
        
        if [ "$line_count" -gt 0 ]; then
            echo ""
            echo "📝 Recent Log Entries (last 5):"
            tail -5 "$LOG_FILE" 2>/dev/null | sed 's/^/  /'
        fi
    else
        echo "📊 Log File: Not found"
    fi
}

# Function to show connection info
show_connection_info() {
    local port=$(jq -r '.telnetPort // 6400' "$CONFIG_FILE" 2>/dev/null || echo "6400")
    
    echo "🔗 Connection Information:"
    echo "  Telnet: telnet localhost $port"
    echo "  Netcat: nc localhost $port"
    echo "  SyncTerm: Use telnet protocol on localhost:$port"
}

# Function to show system resources
show_system_resources() {
    echo "💻 System Resources:"
    
    # CPU usage
    local cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' 2>/dev/null || echo "unknown")
    echo "  CPU Usage: ${cpu_usage}%"
    
    # Memory usage
    local mem_info=$(vm_stat 2>/dev/null | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    if [ -n "$mem_info" ]; then
        local mem_mb=$((mem_info * 4096 / 1024 / 1024))
        echo "  Free Memory: ${mem_mb}MB"
    else
        echo "  Free Memory: unknown"
    fi
    
    # Disk space
    local disk_usage=$(df -h . | tail -1 | awk '{print $5}' 2>/dev/null || echo "unknown")
    echo "  Disk Usage: ${disk_usage}"
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --config     Show configuration details only"
    echo "  -l, --logs       Show recent log entries only"
    echo "  -p, --port       Show port status only"
    echo "  -r, --resources  Show system resources only"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0               Show full status"
    echo "  $0 --config      Show configuration only"
    echo "  $0 --logs        Show recent logs only"
}

# Main execution
main() {
    local config_only=false
    local logs_only=false
    local port_only=false
    local resources_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                config_only=true
                shift
                ;;
            -l|--logs)
                logs_only=true
                shift
                ;;
            -p|--port)
                port_only=true
                shift
                ;;
            -r|--resources)
                resources_only=true
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
    
    echo "📊 C64GPT Server Status"
    echo "======================="
    echo ""
    
    # Show specific information only
    if [ "$config_only" = true ]; then
        get_config_info
        exit 0
    fi
    
    if [ "$logs_only" = true ]; then
        show_recent_logs
        exit 0
    fi
    
    if [ "$port_only" = true ]; then
        check_port_status
        exit 0
    fi
    
    if [ "$resources_only" = true ]; then
        show_system_resources
        exit 0
    fi
    
    # Show full status
    get_server_details
    echo ""
    
    get_config_info
    echo ""
    
    check_port_status
    echo ""
    
    show_connection_info
    echo ""
    
    show_system_resources
    echo ""
    
    show_recent_logs
    echo ""
    
    # Show management commands
    echo "🛠️  Management Commands:"
    echo "  Start:   ./start_server.sh"
    echo "  Stop:    ./stop_server.sh"
    echo "  Status:  ./status_server.sh"
    echo "  Logs:    tail -f $LOG_FILE"
}

# Run main function
main "$@"
