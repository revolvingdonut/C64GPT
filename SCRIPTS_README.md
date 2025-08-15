# C64GPT Server Management Scripts

This directory contains enhanced server management scripts for C64GPT, designed to work with the improved codebase.

## Scripts Overview

### 🚀 `start_server.sh` - Enhanced Server Startup
**Features:**
- ✅ Configuration validation using `jq`
- ✅ Dependency checking (Swift, netcat, jq)
- ✅ Port availability testing
- ✅ Graceful shutdown of existing servers
- ✅ PID file management
- ✅ Comprehensive error handling
- ✅ Colored output for better UX
- ✅ Automatic log file management

**Usage:**
```bash
./start_server.sh
```

**What it does:**
1. Validates configuration file (`Config/config.json`)
2. Checks for required dependencies
3. Tests port availability
4. Stops any existing server gracefully
5. Starts the server with proper logging
6. Provides connection information

### 🛑 `stop_server.sh` - Enhanced Server Shutdown
**Features:**
- ✅ Graceful shutdown with timeout
- ✅ Force kill option for stuck processes
- ✅ Orphaned process cleanup
- ✅ PID file management
- ✅ Port status verification
- ✅ Multiple operation modes
- ✅ Comprehensive status reporting

**Usage:**
```bash
# Graceful shutdown (default)
./stop_server.sh

# Force kill
./stop_server.sh --force

# Show status only
./stop_server.sh --status

# Clean up orphaned processes
./stop_server.sh --cleanup

# Show help
./stop_server.sh --help
```

### 📊 `status_server.sh` - Server Status Monitoring
**Features:**
- ✅ Real-time server status
- ✅ Configuration display
- ✅ Port status checking
- ✅ System resource monitoring
- ✅ Recent log display
- ✅ Connection information
- ✅ Modular output options

**Usage:**
```bash
# Full status (default)
./status_server.sh

# Configuration only
./status_server.sh --config

# Recent logs only
./status_server.sh --logs

# Port status only
./status_server.sh --port

# System resources only
./status_server.sh --resources

# Show help
./status_server.sh --help
```

## Dependencies

The scripts require the following tools (optional dependencies are handled gracefully):

**Required:**
- `bash` - Shell interpreter
- `swift` - Swift compiler/runtime

**Optional (for enhanced features):**
- `jq` - JSON processor for config validation
- `nc` (netcat) - Network utility for port testing
- `ps` - Process status (usually available on Unix systems)

## Configuration Integration

The scripts integrate with the enhanced configuration system:

- **Configuration Validation**: Validates `Config/config.json` before startup
- **Port Management**: Uses configured telnet port for testing
- **Log Management**: Uses configured log file paths
- **Error Handling**: Respects configuration validation rules

## File Management

The scripts manage these files:

- `c64gpt.pid` - Process ID file for server tracking
- `c64gpt.log` - Server log file
- `Config/config.json` - Configuration file

## Error Handling

**Startup Errors:**
- Invalid configuration → Exit with error
- Missing dependencies → Exit with error
- Port conflicts → Warning with suggestion
- Server startup failure → Detailed error reporting

**Shutdown Errors:**
- Graceful shutdown timeout → Automatic force kill
- Orphaned processes → Automatic cleanup
- File cleanup failures → Warning messages

## Monitoring Features

**Status Monitoring:**
- Server uptime tracking
- Memory usage monitoring
- CPU usage tracking
- Port availability checking
- Log file size monitoring

**Resource Management:**
- Automatic PID file cleanup
- Orphaned process detection
- Log file size warnings
- System resource reporting

## Security Features

- **Process Isolation**: Uses PID files for reliable process tracking
- **Graceful Shutdown**: Prevents data corruption
- **Port Validation**: Prevents port conflicts
- **Configuration Validation**: Prevents invalid configurations

## Troubleshooting

**Common Issues:**

1. **Server won't start:**
   ```bash
   ./status_server.sh --logs  # Check recent logs
   ./stop_server.sh --cleanup # Clean up orphaned processes
   ```

2. **Port already in use:**
   ```bash
   ./stop_server.sh --force   # Force kill existing server
   ./start_server.sh          # Restart server
   ```

3. **Configuration issues:**
   ```bash
   ./status_server.sh --config # Check current configuration
   ```

4. **Permission issues:**
   ```bash
   chmod +x *.sh              # Make scripts executable
   ```

## Integration with Code Improvements

These scripts work seamlessly with the code improvements:

- **Configuration Validation**: Uses the new validation system
- **Error Handling**: Leverages improved error reporting
- **Resource Management**: Works with enhanced memory management
- **Logging**: Integrates with improved logging system
- **Performance**: Supports optimized server startup

## Quick Start

```bash
# Start the server
./start_server.sh

# Check status
./status_server.sh

# Stop the server
./stop_server.sh
```

## Advanced Usage

```bash
# Monitor logs in real-time
tail -f c64gpt.log

# Check specific configuration
./status_server.sh --config

# Force restart
./stop_server.sh --force && ./start_server.sh

# Clean up and restart
./stop_server.sh --cleanup && ./start_server.sh
```

The enhanced scripts provide a robust, user-friendly way to manage the C64GPT server with comprehensive error handling, monitoring, and integration with the improved codebase.
