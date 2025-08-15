# C64GPT Unified Management Interface

This document describes the new unified management interface for C64GPT, which combines server management and LLM model management into a single, easy-to-use interface.

## Overview

The unified management interface provides a single window with two tabs:
- **Server Tab**: Manage the C64GPT telnet server (start/stop, view status, copy connection commands)
- **Models Tab**: Manage LLM models (download, remove, set default, configure system prompts)

## Quick Start

### Launch the Unified Interface

```bash
./launch_c64gpt_unified.sh
```

This will:
1. Check dependencies (Swift, Xcode command line tools)
2. Validate configuration
3. Build the application
4. Launch the unified management interface

### Stop the Unified Interface

```bash
./stop_c64gpt_unified.sh
```

### Check Status

```bash
./stop_c64gpt_unified.sh --status
```

## Script Options

### Launch Script Options

- `-h, --help`: Show help message
- `-f, --force`: Force launch even if already running
- `-b, --build`: Build only (don't launch)
- `-v, --validate`: Validate configuration only

### Stop Script Options

- `-h, --help`: Show help message
- `-f, --force`: Force stop (kill -9)
- `-s, --status`: Show status only

## Features

### Server Management
- Start/stop the C64GPT telnet server
- Real-time status monitoring
- Copy connection commands to clipboard
- View server configuration details

### LLM Model Management
- Download models from Ollama
- Remove installed models
- Set default model
- Configure system prompts
- Real-time connection status to Ollama
- Download progress tracking

### Unified Status
- Overall system readiness indicator
- Combined status of server and LLM connection
- Clear visual feedback for all operations

## File Structure

```
C64GPT/
├── launch_c64gpt_unified.sh      # Main launch script
├── stop_c64gpt_unified.sh        # Stop script
├── Sources/PetsponderApp/
│   ├── C64GPTApp.swift           # Main app entry point
│   └── UnifiedManagementView.swift # Unified UI implementation
└── Config/
    └── config.json               # Configuration file
```

**Note**: The old `C64GPT.app` bundle has been removed. The unified interface is launched directly via Swift Package Manager.

## Migration from Old System

The old separate scripts and UI components have been removed:
- ❌ `launch_c64gpt_app.sh`
- ❌ `launch_llm_manager.sh`
- ❌ `stop_llm_manager.sh`
- ❌ `start_server.sh`
- ❌ `stop_server.sh`
- ❌ `status_server.sh`
- ❌ `Sources/PetsponderApp/ContentView.swift`
- ❌ `Sources/PetsponderApp/LLMManagementView.swift`

## Benefits

1. **Simplified Management**: Single interface for all operations
2. **Better UX**: Modern, unified design with clear status indicators
3. **Reduced Complexity**: Fewer scripts to maintain and understand
4. **Improved Reliability**: Centralized process management
5. **Better Integration**: Server and model management work together seamlessly

## Troubleshooting

### Common Issues

1. **Interface won't launch**: Check that Swift and Xcode command line tools are installed
2. **Server won't start**: Verify configuration file is valid
3. **Models not loading**: Ensure Ollama is running and accessible
4. **Permission errors**: Make sure scripts are executable (`chmod +x *.sh`)

### Logs

- Application logs: `c64gpt_unified.log`
- Process ID: `c64gpt_unified.pid`

## Configuration

The unified interface uses the same configuration file as before (`Config/config.json`). All existing configurations will continue to work.

## Future Enhancements

- Configuration editor within the interface
- Log viewer
- Performance monitoring
- Automatic updates
- Plugin system for additional features
