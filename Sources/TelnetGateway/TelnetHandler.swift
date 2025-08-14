import Foundation
import NIO

/// Handles individual Telnet connections and implements RFC854 protocol
public class TelnetHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    
    private let config: ServerConfig
    private let renderer: PETSCIIRenderer
    private var session: TelnetSession?
    
    public init(config: ServerConfig, renderer: PETSCIIRenderer) {
        self.config = config
        self.renderer = renderer
    }
    
    public func channelActive(context: ChannelHandlerContext) {
        print("🔌 New Telnet connection from \(context.remoteAddress?.description ?? "unknown")")
        
        // Create session for this connection
        session = TelnetSession(
            channel: context.channel,
            config: config,
            renderer: renderer
        )
        
        // Send welcome message
        sendWelcomeMessage(context: context)
    }
    
    public func channelInactive(context: ChannelHandlerContext) {
        print("🔌 Telnet connection closed")
        session = nil
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        
        // Process incoming data
        while buffer.readableBytes > 0 {
            if let byte = buffer.readInteger(as: UInt8.self) {
                processByte(byte, context: context)
            }
        }
    }
    
    private func processByte(_ byte: UInt8, context: ChannelHandlerContext) {
        guard let session = session else { return }
        
        // Handle Telnet protocol commands
        if byte == TelnetConstants.IAC {
            session.state = .command
            return
        }
        
        // Handle different states
        switch session.state {
        case .normal:
            handleNormalByte(byte, context: context)
        case .command:
            handleCommand(byte, context: context)
        case .subnegotiation:
            handleSubnegotiation(byte, context: context)
        }
    }
    
    private func handleNormalByte(_ byte: UInt8, context: ChannelHandlerContext) {
        guard let session = session else { return }
        
        // Handle special characters
        switch byte {
        case TelnetConstants.CR:
            // Carriage return - process the line
            let input = session.currentLine
            session.currentLine = ""
            processUserInput(input, context: context)
        case TelnetConstants.LF:
            // Line feed - ignore (already handled by CR)
            break
        case TelnetConstants.BS, TelnetConstants.DEL:
            // Backspace - remove last character
            if !session.currentLine.isEmpty {
                session.currentLine.removeLast()
                // Send backspace sequence
                sendBackspace(context: context)
            }
        default:
            // Echo the character and add to current line
            let char = Character(UnicodeScalar(byte))
            session.currentLine.append(char)
            echoCharacter(char, context: context)
        }
    }
    
    private func handleCommand(_ byte: UInt8, context: ChannelHandlerContext) {
        guard let session = session else { return }
        
        switch byte {
        case TelnetConstants.WILL, TelnetConstants.WONT, TelnetConstants.DO, TelnetConstants.DONT:
            // Handle option negotiation
            session.state = .normal
        case TelnetConstants.SB:
            // Start subnegotiation
            session.state = .subnegotiation
        case TelnetConstants.SE:
            // End subnegotiation
            session.state = .normal
        default:
            session.state = .normal
        }
    }
    
    private func handleSubnegotiation(_ byte: UInt8, context: ChannelHandlerContext) {
        guard let session = session else { return }
        
        if byte == TelnetConstants.SE {
            session.state = .normal
        }
    }
    
    private func processUserInput(_ input: String, context: ChannelHandlerContext) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            sendPrompt(context: context)
            return
        }
        
        // Echo the input with newline
        sendLine("You: \(trimmed)", context: context)
        
        // For now, just echo back (we'll add LLM integration later)
        let response = "AI: Hello! You said: '\(trimmed)'. This is the echo server - LLM integration coming soon!"
        sendLine(response, context: context)
        
        sendPrompt(context: context)
    }
    
    private func sendWelcomeMessage(context: ChannelHandlerContext) {
        let welcome = """
        ┌PETsponder v0.3────────────────────────────────────────┐
        │Welcome to C64GPT!                                     │
        │This is a local LLM that makes your C64 feel sentient. │
        │                                                       │
        │Type something and press Enter to chat...              │
        │                                                       │
        └───────────────────────────────────────────────────────┘
        
        """
        
        sendText(welcome, context: context)
        sendPrompt(context: context)
    }
    
    private func sendPrompt(context: ChannelHandlerContext) {
        sendText("> ", context: context)
    }
    
    private func sendLine(_ text: String, context: ChannelHandlerContext) {
        sendText(text + "\r\n", context: context)
    }
    
    private func sendText(_ text: String, context: ChannelHandlerContext) {
        let rendered = renderer.render(text, mode: config.renderMode, width: config.width)
        sendBytes(rendered, context: context)
    }
    
    private func echoCharacter(_ char: Character, context: ChannelHandlerContext) {
        let rendered = renderer.render(String(char), mode: config.renderMode, width: config.width)
        sendBytes(rendered, context: context)
    }
    
    private func sendBackspace(context: ChannelHandlerContext) {
        // Send backspace sequence: BS SPACE BS
        let backspace = [TelnetConstants.BS, 32, TelnetConstants.BS]
        sendBytes(backspace, context: context)
    }
    
    private func sendBytes(_ bytes: [UInt8], context: ChannelHandlerContext) {
        var buffer = context.channel.allocator.buffer(capacity: bytes.count)
        buffer.writeBytes(bytes)
        context.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("❌ Telnet error: \(error)")
        context.close(promise: nil)
    }
}

/// Telnet protocol constants
private enum TelnetConstants {
    static let IAC: UInt8 = 255
    static let WILL: UInt8 = 251
    static let WONT: UInt8 = 252
    static let DO: UInt8 = 253
    static let DONT: UInt8 = 254
    static let SB: UInt8 = 250
    static let SE: UInt8 = 240
    static let CR: UInt8 = 13
    static let LF: UInt8 = 10
    static let BS: UInt8 = 8
    static let DEL: UInt8 = 127
}

/// Session state for Telnet connection
private enum SessionState {
    case normal
    case command
    case subnegotiation
}

/// Represents a Telnet session
private class TelnetSession {
    let channel: Channel
    let config: ServerConfig
    let renderer: PETSCIIRenderer
    var currentLine: String = ""
    var state: SessionState = .normal
    
    init(channel: Channel, config: ServerConfig, renderer: PETSCIIRenderer) {
        self.channel = channel
        self.config = config
        self.renderer = renderer
    }
}
