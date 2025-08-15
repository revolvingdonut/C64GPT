# C64GPT

A local LLM that makes a Commodore 64 feel sentient through Telnet. Chat with a small, local language model from a C64 (or emulator) with minimalist, immersive terminal UX featuring deliberate pacing for emphasis and ANSI rendering.

## 🎯 What is C64GPT?

C64GPT is a "LAN-only LLM appliance" that creates a conversational AI experience on a Commodore 64. The Mac hosts a daemon that serves Telnet and streams model output with:

- **Deliberate pacing** for **bold**/*italic* emphasis
- **ANSI rendering** for authentic retro feel
- **Natural language commands** (no menu navigation needed)
- **SwiftUI control surface** for model management and metrics

Everything runs locally on your Mac - no internet required after initial model download.

## 🏗️ Architecture

```
+----------------------------+        localhost        +-----------------------+
|  macOS App (SwiftUI)       |<----------------------->|  Control API (SwiftNIO)|
|  - Dashboard, Models, etc. |  (HTTP/WS)             |  + Telnet Gateway      |
|  - Launch/monitor daemon   |                        |  - RFC854 + NAWS       |
+--------------+-------------+                        |  - ANSI render |
               |                                       +----+-------------------+
               | Spawn & supervise                          |
               v                                            | HTTP (localhost)
         +-----+----------------------+                      v
         |  Engine Adapter (Swift)   |              +-------+-----------------+
         |  - Ollama REST client     |              |   Ollama (localhost)   |
         |  - SSE / NDJSON stream    |              |   (GGUF quant models)  |
         +---------------------------+              +------------------------+
                         |
                         | TCP (LAN)
                         v
                +--------+---------+
                |  C64 / Emulator  |
                |  Telnet Client   |
                +------------------+
```

## 🚀 Getting Started

### Prerequisites

- macOS (for the host application)
- [Ollama](https://ollama.ai/) installed and running
- A Commodore 64, emulator, or any Telnet client

### Installation

1. **Clone this repository:**
   ```bash
   git clone https://github.com/yourusername/C64GPT.git
   cd C64GPT
   ```

2. **Build the project:**
   ```bash
   swift build -c release
   ```

3. **Install a model via Ollama:**
   ```bash
   ollama pull gemma2:2b
   ```

4. **Launch the unified management interface:**
   ```bash
   # Using the unified launcher (recommended)
   ./launch_c64gpt_unified.sh
   
   # Or manually
   swift run PetsponderApp
   
   # Stop the interface
   ./stop_c64gpt_unified.sh
   ```

5. **Connect from your C64/emulator:**
   ```bash
   telnet <your-mac-ip> 6400
   ```

## 🎮 Usage

### From the C64 Terminal

- **Natural conversation**: Just type normally and chat with the AI
- **Natural commands**: Say "disconnect now" or "switch to gemma2:2b"
- **Slash commands**: `/help`, `/quit`, `/model <name>`, `/temp <value>`
- **Cancel generation**: `Ctrl-C`

### From the SwiftUI App

The unified management interface provides:
- **Server Tab**: Start/stop the telnet server, view status, copy connection commands
- **Models Tab**: Download models from Ollama, remove models, set default model, configure system prompts
- **Real-time progress**: See download progress and server status updates

## 🎨 Features

### Terminal UX (40×25)
- Minimalist interface with no persistent menus
- Smart text wrapping at 38 columns
- Pager support with `—More—` prompts
- Subtle status line showing session time and tokens/sec

### Emphasis Pacing
- **Bold text** → Deliberate typing (110-130ms/char) with pauses
- *Italic text* → Typewriter effect (70-90ms/char)
- `` `code` `` → Reverse video (ANSI reverse)
- Ellipses `...` → 250ms pause after completion

### Emoji Mapping
- 😀/😊 → `:-)` • ❤️ → `♥` • 👍 → `↑` • 🎉 → `*` • 🤔 → `?` • 😍 → `<3` • 🔥 → `***` • 👋 → `~` • 😂 → `:-D`

## 📁 Project Structure

```
C64GPT/
├── Sources/
│   ├── PetsponderApp/        # SwiftUI unified management app
│   ├── PetsponderDaemon/     # SwiftNIO daemon target
│   ├── TelnetGateway/        # RFC854 + renderer + pacing
│   └── OllamaClient/         # REST + SSE, model operations
├── Tests/
│   ├── TelnetGatewayTests/
│   └── OllamaClientTests/
├── Config/
│   └── config.json          # Configuration file
├── launch_c64gpt_unified.sh # Unified launcher script
├── stop_c64gpt_unified.sh   # Stop script
└── docs/
    └── C64GPT — Design Doc.md
```

## 🔧 Configuration

Edit `Config/config.json` to customize:

- Network ports and addresses
- Default model and engine settings
- Rendering mode (ANSI)
- Pacing speeds and emoji mappings
- Security settings (PIN, CIDR allowlist)

## 🧪 Development

### Building
```bash
swift build -c release
```

### Running Tests
```bash
swift test
```

### Running the App
```bash
# Launch the unified interface
./launch_c64gpt_unified.sh

# Or manually
swift run PetsponderApp
```

## 📊 Performance Targets

- **Engine warm start**: < 3 seconds
- **Time to first token**: < 1.0 second
- **Throughput**: ≥ 15 tokens/sec for tiny models

## 🔒 Security & Privacy

- Control API bound to `127.0.0.1` only
- Telnet bound to private LAN IP with optional CIDR allowlist
- Optional per-session PIN authentication
- No telemetry - everything runs locally
- Optional transcript saving with PII redaction

## 🤝 Contributing

This project is in active development. Check the [Design Document](docs/C64GPT%20—%20Design%20Doc.md) for detailed implementation plans and architecture.

## 📄 License

[Add your license here]

---

**Made with ❤️ for the retro computing community**
