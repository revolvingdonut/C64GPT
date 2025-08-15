# C64 LLM Telnet App — Design Document (v0.3)

**Working title:** *C64GPT*\
**Author:** Scott + ChatGPT\
**Date:** Aug 14, 2025\
**Goal:** Chat with a small, local LLM from a Commodore 64 (or emulator) over Telnet. A SwiftUI macOS app manages models and server lifecycle. The C64 experience is minimalist and immersive—like talking *to the computer*—using pacing for emphasis and ANSI rendering. Everything runs locally on the Mac (Internet only to download/update models).

---

## 1) Product Overview

**Pitch:** A LAN‑only “LLM appliance” that makes a C64 feel sentient. The Mac hosts a daemon that serves Telnet and streams model output with deliberate pacing (for **bold**/*italic*), emoji→PETSCII substitution, and a clean 40×25 interface with no cluttered menus. A SwiftUI GUI starts/stops services, manages models, and shows live metrics.

**Key promises**

- Local-first, fast startup, smooth token streaming.
- Minimalist terminal UX—conversational control, not menus.
- SwiftUI control surface with clear telemetry.

**Primary users**

- Retro enthusiasts (real C64 or emulator).
- Makers who want a private LLM on their LAN.

---

## 2) Scope

**In-scope (MVP)**

- SwiftUI GUI for server control, model management, and live metrics.
- Telnet server with ANSI rendering.
- Conversational control: users can type natural phrases (e.g., “disconnect now”) instead of navigating menus; slash commands still available.
- Emphasis pacing: convert `**bold**` / `*italic*` to slowed per‑char output.
- Emoji mapping: common emoji → ANSI characters.

**Out-of-scope (MVP)**

- GUI chat; voice I/O; multi‑turn long‑term memory; tool use/function calling.

---

## 3) Non‑Goals

- Building a rich menu system on C64.
- Perfect Unicode rendering; we transliterate to a safe ANSI subset.
- Heavy graphics; we optimize readability and feel.

---

## 4) System Architecture

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

**Notes**

- Single Swift workspace: SwiftUI app + SwiftNIO daemon built from one Swift Package. App supervises daemon via `SMAppService` (LaunchAgent‑style).
- Control API and Telnet gateway live in the daemon for low‑latency streaming.
- Engine integration defaults to **Ollama** via `URLSession` streaming; adapters pluggable later.

---

## 5) Terminal UX — Minimalist Conversational Mode

### 5.1 Layout (40×25)

- Transcript fills screen; a subtle status line appears at bottom (session time, tok/s).
- No persistent menus; `/help` reveals commands when asked.
- Smart wrap at 38 columns (2 for glyphs/scroll markers).
- Pager shows `—More—` at row 24; `SPACE` to continue, `Q` to abort.

**Mock (ANSI feel)**

```
┌PETsponder v0.3────────────────────────────────────────┐
│AI : hello, scott.                                     │
│     i’m running locally on your mac.                  │
│You: what can you do here?                             │
│AI : plenty. ask me something curious.                 │
│                                                       │
│>                                                      │
└─────────────── sess:00:03 tok/s:22 ───────────────────┘
```

### 5.2 Conversational Delivery & Emphasis Pacing

**Goal:** Replace bold/italics/emojis with pacing and simple cues so it *feels* like a computer speaking.

**Markup detection (streaming‑safe):**

- Detect `**bold**`, `*italic*`, inline code `` `code` `` across token boundaries with a 256‑char rolling buffer; tolerate unmatched markers.

**Pacing rules:**

- Normal text: flush every **20–40 ms** per burst.
- *Italic* → **typewriter**: **70–90 ms/char**.
- **Bold** → **deliberate**: **110–130 ms/char** + **150 ms** pause before/after the span.
- `` `code` `` → **reverse video** (ANSI reverse), normal cadence.
- Ellipses `...` → +**250 ms** pause after completion.
- Sentence end `.?!` → +**80–120 ms** pause.

**Emoji mapping (defaults):** 😀/😊→`:-)` • ❤️→`♥` • 👍→`↑` • 🎉→`*` • 🤔→`?` • 😍→`<3` • 🔥→`***` • 👋→`~` • 😂→`:-D`\
Unknown emoji are passed through unchanged.

### 5.3 Natural‑Language Commands (no menuing)

- The gateway performs light NLU for intents like: **disconnect**, **quit**, \*\*switch to \*\*, \*\*set temperature to \*\*, **set width <40|80>**.
- Slash commands still exist for power users: `/quit`, `/model <name>`, `/temp <n>`, `/wrap <on|off>`, `/clear`, `/save`, `/width <40|80>`.

### 5.4 Sideband Command Tags (from the model)

- The system prompt asks the model to optionally emit hidden tags that the gateway executes, then strips from output.\
  **Syntax (single token on its own):**

```
<cmd:quit/>
<cmd:clear/>
<cmd:model name="gemma-2:2b"/>
<cmd:temp value="0.8"/>
<cmd:width value="80"/>

```

---

## 6) SwiftUI GUI (Control Surface)

**Core views**

1. **Dashboard** — process status, active sessions, TTFT, tokens/sec, CPU/RAM; live via WebSocket.
2. **Models** — list local models, pull/remove via Ollama, set default, disk usage.
3. **Sessions** — per‑connection stats (ttft, tok/s, cancels, errors).
4. **Settings** — ports, default model, pacing speeds, emoji map, logging, optional PIN.

**Implementation notes**

- Networking: `URLSession` for REST + `URLSessionWebSocketTask` for metrics/events.
- State: Observable `AppState` with Combine publishers feeding SwiftUI views.
- Daemon lifecycle: `SMAppService` to register/launch; graceful restart and health checks.

---

## 7) Control API / Daemon (SwiftNIO)

**REST (localhost)**

- `GET /health` — daemon/engine/telnet readiness.
- `GET /stats` — global metrics snapshot.
- `GET /models` — list installed; `POST /models/pull { name }`; `DELETE /models/{ name }`.
- `POST /engine/start { backend:"ollama" }`; `POST /engine/stop`.
- `POST /chat/start { session_id?, params }` — allocate session defaults.
- `POST /params` — set defaults; `GET /params`.

**WebSocket/SSE**

- `GET /events` — session join/leave, engine restarts.
- `GET /metrics/stream` — { ttft, tokps, queue\_depth, cpu, ram } @1s.

**Per‑chat system prompt (inserted every time)**

```
You are the voice of a local computer on a Commodore 64 terminal. Keep replies concise, friendly, and plain text. Avoid heavy markdown. If the user clearly asks to perform a control action (quit, clear, switch model, set temperature, change width), emit an invisible sideband tag using this exact syntax, on its own token: <cmd:ACTION .../>. Then continue your reply naturally.
```

---

## 8) Telnet Gateway

**Protocol handling**

- RFC 854 negotiation; NAWS if emulator reports width/height; default to 40×25.
- Idle timeout; keep‑alive pings every 60s.
- Optional per‑session 4‑digit PIN entry.

**Session lifecycle**

1. Connect → negotiate → detect ANSI.
2. Draw splash; show current model; hint “type /help”.
3. Stream tokens with pacing; `Ctrl‑C` cancels generation.
4. `/quit` or “disconnect now” ends session gracefully.

**Rendering**

- Unicode→ANSI transliteration; unsupported glyphs → `▒`.
- Greedy wrap at `WIDTH-2`; pager `—More—` at row 24.
- Minimal cursor control (avoid flicker).

---

## 9) Performance Targets

- **Engine warm start:** < 3 s (model already loaded).
- **TTFT:** < 1.0 s on target Mac for tiny models.
- **Throughput:** ≥ 15 tok/s for tiny models (4‑bit quant), with graceful backpressure.

---

## 10) Security & Privacy

- Control API bound to `127.0.0.1`.
- Telnet bound to a private LAN IP; optional CIDR allowlist.
- Optional per‑session PIN before drawing the UI.
- No telemetry; local rotating logs; optional transcript saving with simple PII redaction.

---

## 11) Logging & Metrics

- Rotating daily logs; session IDs, commands, errors, engine restarts.
- Metrics: ttft, tokens/sec (inst/avg), active sessions, cancels, RAM/VRAM, model load time, queue depth.
- `/metrics/stream` provides 1s updates to the GUI.

---

## 12) Configuration & Persistence

- `Config/config.toml`: ports, defaults, theme, model, auth, pacing speeds, emoji map.
- `models/` (managed by Ollama).
- `transcripts/` (if enabled) with datestamped files.

**Example**

```toml
[network]
control_host = "127.0.0.1"
control_port = 4333
listen_addr  = "0.0.0.0"
telnet_port  = 6400

[engine]
backend = "ollama"
default_model = "<set in GUI>"

[render]
mode = "ansi"
width = 40
wrap = true
italic_pace_ms = 80
bold_pace_ms = 120
pause_sentence_ms = 100

[security]
auth_pin = ""
allowed_cidr = "192.168.1.0/24"

[logging]
level = "info"
transcripts = false

[emoji]
"🙂" = "☺"
"❤️" = "♥"
"👍" = "↑"
"👉" = "→"
"🎉" = "*"
"🤔" = "?"
```

---

## 13) Implementation Plan

**Phase 0 — Spike (1–2 days)**

- Swift Package with targets: `PetsponderApp` (SwiftUI) and `PetsponderDaemon` (SwiftNIO).
- Telnet echo server + ANSI rendering.
- Ollama client: streaming SSE to console.

**Phase 1 — MVP (1–2 weeks)**

- End‑to‑end streaming chat over Telnet with pacing engine.
- Minimalist C64 UI; NL intent parsing + sideband tag execution; `Ctrl‑C` cancel.
- SwiftUI dashboard: start/stop daemon, select/pull models, live tok/s & TTFT.

**Phase 2 — Polish (1–2 weeks)**

- Metrics charts; transcripts; better ANSI mappings; color themes; PIN auth; NAWS support; emoji map editor.

**Phase 3 — Nice‑to‑have**

- 80‑column emulator mode; model catalogs; throughput test; per‑session presets.

---

## 14) Cursor Agent Build Plan & Repo Layout

**Repository layout**

```
/ (workspace root)
  Package.swift
  /Sources
    /PetsponderApp        # SwiftUI app target
    /PetsponderDaemon     # SwiftNIO daemon target (Control API + Telnet)
    /TelnetGateway        # module: RFC854 + renderer + pacing
    /OllamaClient         # module: REST + SSE, model ops
  /Tests
    /TelnetGatewayTests
    /OllamaClientTests
  /Config
    config.toml
```

**Atomic tasks for Cursor**

1. Scaffold Swift Package (targets above); add minimal `main.swift` for daemon.
2. Implement **TelnetGateway**: negotiation, echo, ANSI rendering.
3. Implement **OllamaClient**: `pull`, `list`, `generate` (SSE/NDJSON).
4. Wire **pacing engine** into Telnet stream; implement markup detector & scheduler.
5. Implement **Control API** (endpoints in §7); WS metrics/events.
6. Build **SwiftUI Dashboard**: status tiles, model picker, pull/remove; live tok/s & TTFT.
7. Implement **NLU intents** + observe [**cmd:.../**](cmd:.../) tags; add `/help`.
8. Add **tests**: unit (parser/pacing), integration (`nc localhost 6400` chat + `Ctrl‑C`).

**Build & run**

- Build: `swift build -c release`
- Run daemon: `.build/release/PetsponderDaemon`
- Run app: Xcode scheme `PetsponderApp`

**Acceptance tests (agent can run)**

- Telnet connects; paced *italic*/**bold** visible.
- “disconnect now” closes session (no slash).
- “switch to gemma-2:2b” changes model (GUI reflects).
- ❤️/👍 map to ♥/↑.

**Guardrails**

- Keep ANSI cursor control minimal; avoid flicker.
- Never block token stream; apply backpressure only.
- All configuration via `Config/config.toml`; sensible defaults if missing.

---

## 15) Risks & Mitigations

- **ANSI fidelity** — Unicode lossiness. *Mitigation:* strict subset, graceful fallback.
- **Performance variance** — lower‑end Macs. *Mitigation:* label models by perf; sane defaults.
- **Client diversity** — emulators vs hardware. *Mitigation:* NAWS + `/width` override, `/ansi` switch.
- **User confusion** — minimal UI. *Mitigation:* `/help` and gentle one‑line hints on connect.

---

## 16) Acceptance Criteria (MVP)

- From a C64/emulator: `telnet <mac-ip> <port>` shows splash and accepts input.
- Token streaming appears within \~1s for a short prompt on a modern Mac; pacing effects are visible.
- Natural‑language intents like “disconnect now” or “switch to gemma” take effect without slash commands.
- GUI starts/stops daemon, pulls/removes models, sets default model, displays live tok/s and TTFT.
- Graceful disconnects; optional transcripts saved; logs show lifecycle events.

