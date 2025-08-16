# C64GPT Core Design Document

## Overview

C64GPT is a retro-style telnet-based AI chat application that provides a Commodore 64-inspired interface for interacting with Large Language Models (LLMs). The system combines modern AI capabilities with a nostalgic terminal experience, featuring word-level text wrapping, ANSI rendering, and a unified management interface.

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Telnet Client │    │  SwiftUI App    │    │   Ollama API    │
│   (SyncTERM,    │◄──►│  (Management    │◄──►│   (Local LLM    │
│    PuTTY, etc.) │    │   Interface)    │    │    Server)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    C64GPT Core System                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  TelnetGateway  │  │  PetsponderApp  │  │  PetsponderDaemon│ │
│  │  (Network Layer)│  │  (UI Layer)     │  │  (Server Process)│ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Core Components

1. **TelnetGateway** - Network protocol handling and session management
2. **PetsponderApp** - SwiftUI-based management interface
3. **PetsponderDaemon** - Background server process
4. **OllamaClient** - LLM API integration

## Component Details

### 1. TelnetGateway

**Purpose**: Handles telnet protocol, user input processing, and AI response rendering.

**Key Features**:
- Telnet protocol implementation (IAC, option negotiation)
- Word-level text wrapping for user input
- ANSI rendering with emoji translation
- Session state management
- Character-by-character input processing
- Backspace handling with cursor tracking

**Core Classes**:

#### TelnetHandler
- **Main Handler**: Processes incoming telnet bytes and manages session state
- **Session Management**: Tracks user sessions, cursor positions, and input state
- **Word Wrap Logic**: Implements character-level and word-level text wrapping
- **Input Validation**: Security checks and natural language command parsing

#### TelnetSession
- **State Tracking**: Manages session state (normal, command, subnegotiation)
- **Cursor Management**: Tracks cursor position and word boundaries
- **Word Wrap**: Implements word-level wrapping with proper character handling
- **Backspace Support**: Handles backspace with cursor position updates

#### ANSIRenderer
- **Text Rendering**: Converts text to ANSI escape sequences
- **Emoji Translation**: Maps emoji characters to text equivalents
- **Word Wrapping**: Handles text wrapping for AI responses
- **Character Encoding**: Manages UTF-8 to ANSI conversion

### 2. PetsponderApp

**Purpose**: Provides a modern SwiftUI interface for managing the C64GPT system.

**Key Features**:
- Server start/stop controls
- Model management and switching
- Configuration editing
- Real-time status monitoring
- Process management

**Core Classes**:

#### ServerManager
- **Process Management**: Launches and monitors the daemon process
- **Configuration**: Manages server configuration and model settings
- **Status Monitoring**: Tracks server state and connection status
- **UI Updates**: Provides observable state for SwiftUI views

#### UnifiedManagementView
- **Main Interface**: Primary management dashboard
- **Server Controls**: Start/stop/restart functionality
- **Model Selection**: Dropdown for choosing LLM models
- **Configuration**: Real-time config editing
- **Status Display**: Server status and connection information

### 3. PetsponderDaemon

**Purpose**: Background server process that runs the telnet server and manages AI interactions.

**Key Features**:
- Telnet server initialization and management
- Configuration loading and validation
- AI client integration
- Process lifecycle management

**Core Components**:

#### Main Process
- **Server Startup**: Initializes telnet server with configuration
- **Configuration Loading**: Loads settings from JSON and environment variables
- **Error Handling**: Graceful error handling and logging
- **Signal Handling**: Proper shutdown on termination signals

### 4. OllamaClient

**Purpose**: Provides integration with the Ollama LLM API.

**Key Features**:
- Streaming text generation
- Model management
- API communication
- Response processing

**Core Classes**:

#### OllamaClient
- **API Communication**: HTTP requests to Ollama server
- **Streaming Support**: Handles streaming text generation
- **Model Operations**: List, pull, and manage models
- **Error Handling**: Robust error handling and retry logic

## Data Flow

### User Input Flow

```
1. Telnet Client → TelnetHandler.handleNormalByte()
2. Character Processing → Word Wrap Check
3. Input Validation → Natural Language Command Check
4. AI Processing → OllamaClient.generateStream()
5. Response Rendering → ANSIRenderer.render()
6. Output → Telnet Client
```

### Word Wrap Flow

```
1. Character Received → checkAndWrapIfNeeded()
2. Position Check → If exceeds width - 1
3. Word Processing → Clear current word from line
4. Line Break → Send CR + LF
5. Word Output → Send word to new line (no prompt)
6. Cursor Update → Position cursor after word
```

## Configuration

### Configuration Structure

```json
{
  "port": 6400,
  "width": 40,
  "wrap": true,
  "maxInputLength": 1000,
  "defaultModel": "llama3.2:3b",
  "systemPrompt": "You are a helpful AI assistant...",
  "ollamaUrl": "http://localhost:11434"
}
```

### Environment Variables

- `C64GPT_PORT` - Telnet server port
- `C64GPT_WIDTH` - Terminal width
- `C64GPT_WRAP` - Enable word wrapping
- `C64GPT_MAX_INPUT_LENGTH` - Maximum input length
- `C64GPT_DEFAULT_MODEL` - Default LLM model
- `C64GPT_OLLAMA_URL` - Ollama server URL

## Security Features

### Input Validation

- **Length Limits**: Configurable maximum input length
- **Character Validation**: ASCII validation and null byte detection
- **Pattern Filtering**: Blocks potentially dangerous patterns
- **Command Injection Prevention**: Validates against script injection attempts

### Natural Language Commands

- **quit/exit/disconnect** - Graceful connection termination
- **clear** - Clear terminal screen
- **switch to model** - Change LLM model dynamically

## Word Wrap Implementation

### User Input Wrapping

**Algorithm**:
1. Track cursor position and current word
2. Check if adding character exceeds line width
3. For spaces: Wrap before space, reset cursor
4. For non-spaces: Clear word from current line, move to new line
5. Position cursor correctly for continued typing

**Key Features**:
- Word-level wrapping (keeps words intact)
- No character duplication
- No prompts on wrapped lines
- Proper cursor positioning
- Backspace support with cursor tracking

### AI Response Wrapping

**Algorithm**:
1. Process text through ANSIRenderer
2. Apply word-level wrapping to response text
3. Handle emoji translation
4. Maintain proper line breaks and formatting

## Deployment

### Build System

- **Swift Package Manager**: Primary build system
- **Multiple Targets**: Separate targets for each component
- **Release Builds**: Production-optimized builds
- **Debug Support**: Development builds with debugging

### Launch Scripts

- **launch_c64gpt_unified.sh**: Unified management interface launcher
- **stop_c64gpt_unified.sh**: Graceful shutdown script
- **Dependency Checking**: Validates system requirements
- **Configuration Validation**: Ensures proper setup

## Testing

### Test Coverage

- **Unit Tests**: Core functionality testing
- **Integration Tests**: Component interaction testing
- **Configuration Tests**: Settings validation
- **Word Wrap Tests**: Text wrapping behavior verification

### Test Structure

```
Tests/
├── OllamaClientTests/
│   └── OllamaClientTests.swift
└── TelnetGatewayTests/
    └── TelnetGatewayTests.swift
```

## Performance Characteristics

### Scalability

- **Single Server**: Designed for single-server deployment
- **Session Management**: Efficient session tracking
- **Memory Usage**: Minimal memory footprint
- **CPU Usage**: Low CPU utilization for typical usage

### Limitations

- **Single Thread**: Telnet server runs on single thread
- **Concurrent Users**: Limited by single-threaded design
- **Model Loading**: Dependent on Ollama server performance
- **Network**: Limited by telnet protocol overhead

## Future Considerations

### Potential Enhancements

- **Multi-threading**: Support for multiple concurrent users
- **Plugin System**: Extensible architecture for new features
- **Database Integration**: Persistent session storage
- **Authentication**: User authentication and authorization
- **Logging**: Comprehensive logging and monitoring
- **Metrics**: Performance and usage metrics

### Architecture Evolution

- **Modular Design**: Extract shared components into libraries
- **Microservices**: Split into separate services
- **API Gateway**: REST API for modern clients
- **Web Interface**: Web-based management interface

## Dependencies

### External Dependencies

- **SwiftNIO**: Asynchronous networking framework
- **SwiftUI**: User interface framework
- **Foundation**: Core Swift functionality

### System Requirements

- **macOS**: Primary development and deployment platform
- **Ollama**: Local LLM server
- **Telnet Client**: Any telnet-compatible client
- **Swift**: Swift 5.0 or later

## Documentation

### Current Documentation

- **WORD_WRAP_USER_INPUT.md**: Detailed word wrap implementation
- **UNIFIED_MANAGEMENT_README.md**: Management interface guide
- **SCRIPTS_README.md**: Launch script documentation
- **UNIFIED_SERVER_FIXES.md**: Server fixes and improvements

### Code Documentation

- **Inline Comments**: Comprehensive code comments
- **Function Documentation**: Swift documentation comments
- **Architecture Comments**: High-level design explanations
- **Example Usage**: Code examples and usage patterns

---

*This document serves as the foundation for C64GPT development. Future feature additions should reference this document and include their own design documents that build upon this core architecture.*
