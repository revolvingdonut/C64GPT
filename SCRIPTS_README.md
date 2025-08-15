# C64GPT Unified Management Scripts

This directory contains the unified management scripts for C64GPT, designed to work with the unified management interface.

## Scripts Overview

### 🚀 `launch_c64gpt_unified.sh` - Unified Interface Launcher
**Features:**
- ✅ Configuration validation using `jq`
- ✅ Dependency checking (Swift, Xcode command line tools)
- ✅ Port availability testing
- ✅ Graceful shutdown of existing processes
- ✅ PID file management
- ✅ Comprehensive error handling
- ✅ Colored output for better UX
- ✅ Automatic log file management

**Usage:**
```bash
./launch_c64gpt_unified.sh
```

**Options:**
- `-h, --help`: Show help message
- `-f, --force`: Force launch even if already running
- `-b, --build`: Build only (don't launch)
- `-v, --validate`: Validate configuration only

**What it does:**
1. Validates configuration file (`Config/config.json`)
2. Checks for required dependencies
3. Tests port availability
4. Stops any existing processes gracefully
5. Builds the unified management interface
6. Launches the interface with proper logging
7. Provides connection information

### 🛑 `stop_c64gpt_unified.sh` - Unified Interface Shutdown
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
./stop_c64gpt_unified.sh

# Force kill
./stop_c64gpt_unified.sh --force

# Show status only
./stop_c64gpt_unified.sh --status

# Clean up orphaned processes
./stop_c64gpt_unified.sh --cleanup

# Show help
./stop_c64gpt_unified.sh --help
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

- `c64gpt_unified.pid` - Process ID file for interface tracking
- `c64gpt_unified.log` - Interface log file
- `Config/config.json` - Configuration file

## Error Handling

**Startup Errors:**
- Invalid configuration → Exit with error
- Missing dependencies → Exit with error
- Port conflicts → Warning with suggestion
- Interface startup failure → Detailed error reporting

**Shutdown Errors:**
- Graceful shutdown timeout → Automatic force kill
- Orphaned processes → Automatic cleanup
- File cleanup failures → Warning messages

## Monitoring Features

**Status Monitoring:**
- Interface uptime tracking
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

1. **Interface won't start:**
   ```bash
   ./stop_c64gpt_unified.sh --status  # Check status
   ./stop_c64gpt_unified.sh --cleanup # Clean up orphaned processes
   ```

2. **Port already in use:**
   ```bash
   ./stop_c64gpt_unified.sh --force   # Force kill existing processes
   ./launch_c64gpt_unified.sh         # Restart interface
   ```

3. **Configuration issues:**
   ```bash
   ./launch_c64gpt_unified.sh --validate # Validate configuration
   ```

4. **Permission issues:**
   ```bash
   chmod +x *.sh              # Make scripts executable
   ```

## Integration with Unified Management Interface

These scripts work seamlessly with the unified management interface:

- **Configuration Validation**: Uses the new validation system
- **Error Handling**: Leverages improved error reporting
- **Resource Management**: Works with enhanced memory management
- **Logging**: Integrates with improved logging system
- **Performance**: Supports optimized interface startup

## Quick Start

```bash
# Launch the unified interface
./launch_c64gpt_unified.sh

# Check status
./stop_c64gpt_unified.sh --status

# Stop the interface
./stop_c64gpt_unified.sh
```

## Advanced Usage

```bash
# Monitor logs in real-time
tail -f c64gpt_unified.log

# Force restart
./stop_c64gpt_unified.sh --force && ./launch_c64gpt_unified.sh

# Clean up and restart
./stop_c64gpt_unified.sh --cleanup && ./launch_c64gpt_unified.sh

# Build only
./launch_c64gpt_unified.sh --build
```

## Unified Management Interface Features

The unified interface provides:

- **Server Management**: Start/stop the telnet server, view status, copy connection commands
- **LLM Model Management**: Download models from Ollama, remove models, set default model, configure system prompts
- **Real-time Progress**: See download progress and server status updates
- **Configuration Management**: Change settings with automatic restart notifications
- **Status Monitoring**: Continuous monitoring of server and model status

The enhanced scripts provide a robust, user-friendly way to manage the C64GPT unified interface with comprehensive error handling, monitoring, and integration with the improved codebase.
