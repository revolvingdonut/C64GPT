import Foundation
import NIO
import OllamaClient

/// Handles individual Telnet connections and implements RFC854 protocol
public class TelnetHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    
    private let config: ServerConfig
    private let renderer: ANSIRenderer
    private let ollamaClient: OllamaClient
    private var session: TelnetSession?
    private var isProcessing = false
    
    // Connection tracking
    private static var activeConnections = 0
    private static let connectionLock = NSLock()
    
    public init(config: ServerConfig, renderer: ANSIRenderer, ollamaClient: OllamaClient) {
        self.config = config
        self.renderer = renderer
        self.ollamaClient = ollamaClient
    }
    
    public func channelActive(context: ChannelHandlerContext) {
        // Track active connections
        Self.connectionLock.lock()
        Self.activeConnections += 1
        Self.connectionLock.unlock()
        
        logInfo("🔌 New Telnet connection from \(context.remoteAddress?.description ?? "unknown")")
        logAudit("Connection established from \(context.remoteAddress?.description ?? "unknown")")
        
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
        // Track connection closure
        Self.connectionLock.lock()
        Self.activeConnections = max(0, Self.activeConnections - 1)
        Self.connectionLock.unlock()
        
        logInfo("🔌 Telnet connection closed")
        logAudit("Connection closed from \(context.remoteAddress?.description ?? "unknown")")
        session = nil
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        
        // Process incoming data synchronously
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
        case .waitingForOption:
            handleOptionCode(byte, context: context)
        }
    }
    
    private func handleNormalByte(_ byte: UInt8, context: ChannelHandlerContext) {
        guard let session = session else { return }
        

        
        // Handle special characters
        switch byte {
        case TelnetConstants.CR, TelnetConstants.LF:
            // Carriage return or line feed - process the line
            if !session.currentLine.isEmpty {
                let input = session.currentLine
                session.currentLine = ""
                // Add blank line after user input is complete
                sendBytes([13, 10], context: context) // CR + LF for blank line after user input
                processUserInput(input, context: context)
            }
        case TelnetConstants.BS, TelnetConstants.DEL:
            // Backspace - remove last character
            if !session.currentLine.isEmpty {
                session.currentLine.removeLast()
                // Send backspace sequence
                sendBackspace(context: context)
            }
        case 32: // Space character
            // Handle space character - ensure it's properly echoed
            session.currentLine.append(" ")
            echoCharacter(" ", context: context) // Use consistent character rendering
            
        case 3: // ETX (End of Text) - ignore this control character
            // Don't echo or process this character
            break
            
        default:
            // Echo the character as user types and add to current line
            let char = Character(UnicodeScalar(byte))
            session.currentLine.append(char)
            // Send character through word wrap system for consistent column tracking
            echoCharacter(char, context: context)
        }
    }
    
    private func handleCommand(_ byte: UInt8, context: ChannelHandlerContext) {
        guard let session = session else { return }
        
        switch byte {
        case TelnetConstants.WILL, TelnetConstants.WONT, TelnetConstants.DO, TelnetConstants.DONT:
            // Handle option negotiation - respond with DONT/WONT to disable all options
            let response: UInt8
            if byte == TelnetConstants.WILL || byte == TelnetConstants.DO {
                response = byte == TelnetConstants.WILL ? TelnetConstants.DONT : TelnetConstants.WONT
            } else {
                response = byte == TelnetConstants.WONT ? TelnetConstants.DONT : TelnetConstants.WONT
            }
            
            // Send response: IAC + response + option code
            // We need to read the option code first
            session.state = .waitingForOption
            session.lastCommand = byte
            session.lastResponse = response
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
    
    private func handleOptionCode(_ byte: UInt8, context: ChannelHandlerContext) {
        guard let session = session else { return }
        
        // Send the response: IAC + response + option code
        let response = [TelnetConstants.IAC, session.lastResponse, byte]
        sendBytes(response, context: context)
        
        // Reset state
        session.state = .normal
        session.lastCommand = 0
        session.lastResponse = 0
    }
    
    private func processUserInput(_ input: String, context: ChannelHandlerContext) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            sendPrompt(context: context)
            return
        }
        
        // Validate input for security
        guard validateInput(trimmed) else {
            sendLine("AI: Input validation failed. Please check your input and try again.", context: context)
            sendPrompt(context: context)
            return
        }
        
        // Check for natural language commands
        if let command = parseNaturalLanguageCommand(trimmed) {
            executeCommand(command, context: context)
            return
        }
        
        // Generate AI response
        Task {
            await self.generateAIResponse(for: trimmed, context: context)
        }
    }
    
    /// Validates user input for security and safety
    private func validateInput(_ input: String) -> Bool {
        // Check input length from configuration
        guard input.count <= config.maxInputLength else { return false }
        
        // Check for null bytes or invalid characters
        guard !input.contains(where: { $0.asciiValue == nil || $0.asciiValue == 0 }) else { return false }
        
        // Check for potentially dangerous patterns
        let dangerousPatterns = [
            "javascript:", "data:", "vbscript:", "onload=", "onerror=",
            "eval(", "exec(", "system(", "shell_exec("
        ]
        
        let lowercasedInput = input.lowercased()
        for pattern in dangerousPatterns {
            if lowercasedInput.contains(pattern) {
                return false
            }
        }
        
        return true
    }
    
    private func parseNaturalLanguageCommand(_ input: String) -> String? {
        let lowercased = input.lowercased()
        
        // Natural language command patterns
        if lowercased.contains("disconnect") || lowercased.contains("quit") || lowercased.contains("exit") {
            return "quit"
        }
        if lowercased.contains("clear") {
            return "clear"
        }
        if lowercased.contains("switch to") || lowercased.contains("use model") {
            // Extract model name
            let words = input.components(separatedBy: " ")
            if let modelIndex = words.firstIndex(where: { $0.lowercased() == "to" || $0.lowercased() == "model" }) {
                let modelName = words.dropFirst(modelIndex + 1).joined(separator: " ")
                return "model \(modelName)"
            }
        }
        
        return nil
    }
    
    private func executeCommand(_ command: String, context: ChannelHandlerContext) {
        switch command {
        case "quit":
            sendLine("AI: Goodbye! Disconnecting...", context: context)
            context.close(promise: nil)
        case "clear":
            // Send clear screen sequence
            let clearScreen = "\u{1B}[2J\u{1B}[H" // ANSI clear screen
            sendBytes(Array(clearScreen.utf8), context: context)
            sendWelcomeMessage(context: context)
        default:
            if command.hasPrefix("model ") {
                let modelName = String(command.dropFirst(6))
                sendLine("AI: Switching to model: \(modelName)", context: context)
                // TODO: Implement model switching
            }
        }
    }
    
    private func generateAIResponse(for input: String, context: ChannelHandlerContext) async {
        // Prevent concurrent processing
        guard !isProcessing else {
            sendLine("AI: Please wait for the current response to complete.", context: context)
            sendPrompt(context: context)
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let fullResponse = try await generateResponseFromAI(for: input)
            sendAIResponse(fullResponse, context: context)
        } catch {
            sendLine("AI: Sorry, I encountered an error: \(error.localizedDescription)", context: context)
            sendPrompt(context: context)
        }
    }
    
    private func generateResponseFromAI(for input: String) async throws -> String {
        let fullPrompt = "\(config.systemPrompt)\n\nUser: \(input)\nAI:"
        
        let stream = ollamaClient.generateStream(
            model: config.defaultModel,
            prompt: fullPrompt,
            options: GenerateOptions(temperature: 0.7)
        )
        
        var fullResponse = ""
        
        for try await chunk in stream {
            if !chunk.response.isEmpty {
                let filteredResponse = chunk.response
                    .replacingOccurrences(of: #"<[Cc][Mm][Dd]:[^>]*/?>"#, with: "", options: String.CompareOptions.regularExpression)
                
                if !filteredResponse.isEmpty {
                    fullResponse += filteredResponse
                }
            }
        }
        
        return fullResponse
    }
    

    
    private func sendAIResponse(_ response: String, context: ChannelHandlerContext) {
        if !response.isEmpty {
            let responseWithPrefix = "AI: \(response)"
            let rendered = renderer.render(responseWithPrefix, width: config.width)
            sendBytes(rendered, context: context)
        }
        
        // Add proper line breaks after AI response
        sendBytes([13, 10], context: context)
        sendPrompt(context: context)
    }
    
    private func sendWelcomeMessage(context: ChannelHandlerContext) {
        // Just send the prompt without any intro text
        sendPrompt(context: context)
    }
    
    private func sendPrompt(context: ChannelHandlerContext) {
        // Send prompt directly without word wrapping to avoid extra spaces
        let ansiBytes = Array("> ".utf8)
        sendBytes(ansiBytes, context: context)
    }
    
    private func sendLine(_ text: String, context: ChannelHandlerContext) {
        sendText(text + "\r\n", context: context)
    }
    
    private func sendText(_ text: String, context: ChannelHandlerContext) {
        let rendered = renderer.render(text, width: config.width)
        sendBytes(rendered, context: context)
    }
    
    private func echoCharacter(_ char: Character, context: ChannelHandlerContext) {
        // Use the renderer's character conversion method
        let rendered = renderer.renderCharacter(char)
        sendBytes(rendered, context: context)
    }
    
    private func sendBackspace(context: ChannelHandlerContext) {
        // Send backspace sequence: BS SPACE BS
        let backspace = [TelnetConstants.BS, 32, TelnetConstants.BS]
        sendBytes(backspace, context: context)
    }
    
    private func sendBytes(_ bytes: [UInt8], context: ChannelHandlerContext) {
        context.eventLoop.execute {
            var buffer = context.channel.allocator.buffer(capacity: bytes.count)
            buffer.writeBytes(bytes)
            context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
        }
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logError("❌ Telnet error: \(error)")
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
    case waitingForOption
}

/// Represents a Telnet session
private class TelnetSession {
    let channel: Channel
    let config: ServerConfig
    let renderer: ANSIRenderer
    var currentLine: String = ""
    var state: SessionState = .normal
    var lastCommand: UInt8 = 0
    var lastResponse: UInt8 = 0
    
    init(channel: Channel, config: ServerConfig, renderer: ANSIRenderer) {
        self.channel = channel
        self.config = config
        self.renderer = renderer
    }
}
