import Foundation
import SwiftUI

// MARK: - Constants
public struct Constants {
    // Network
    public static let defaultTelnetPort = 6400
    public static let defaultControlPort = 4333
    public static let defaultListenAddress = "0.0.0.0"
    public static let defaultControlHost = "127.0.0.1"
    public static let defaultOllamaBaseURL = "http://localhost:11434"
    
    // Display
    public static let defaultWidth = 40
    public static let defaultMaxInputLength = 1000
    public static let defaultRequestTimeout: TimeInterval = 30.0
    public static let defaultResourceTimeout: TimeInterval = 300.0
    
    // Rate Limiting
    public static let defaultRateLimitRequests = 100
    public static let defaultRateLimitWindow = 60
    
    // Models
    public static let defaultModel = "gemma2:2b"
    public static let defaultSystemPrompt = "You are a helpful AI assistant. Keep replies concise, friendly, and natural. Respond in plain text without special formatting or markdown."
    
    // Messages
    public static let serverStartedMessage = "Server started successfully!"
    public static let serverStoppedMessage = "Server stopped."
    public static let serverStartingMessage = "Starting server..."
    public static let serverStoppingMessage = "Stopping server..."
    public static let telnetCommand = "telnet localhost 6400"
    
    // File Paths
    public static let configPath = "Config/config.json"
    public static let logPath = "c64gpt.log"
    public static let pidPath = "c64gpt_unified.pid"
}

// MARK: - Error Handler
public class ErrorHandler {
    public static let shared = ErrorHandler()
    
    private init() {}
    
    public func handle(_ error: Error, context: String = "") -> String {
        let errorMessage = "\(context.isEmpty ? "" : "\(context): ")\(error.localizedDescription)"
        // Note: Logging should be handled by the calling module
        return errorMessage
    }
    
    public func handleNetworkError(_ error: Error) -> String {
        return handle(error, context: "Network Error")
    }
    
    public func handleConfigurationError(_ error: Error) -> String {
        return handle(error, context: "Configuration Error")
    }
    
    public func handleServerError(_ error: Error) -> String {
        return handle(error, context: "Server Error")
    }
}

// MARK: - Shared Configuration
public struct SharedConfiguration: Codable {
    // MARK: - Network Configuration
    public let listenAddress: String
    public let telnetPort: Int
    public let controlHost: String
    public let controlPort: Int
    
    // MARK: - Rendering Configuration
    public let width: Int
    public let wrap: Bool
    
    // MARK: - Security Configuration
    public let maxInputLength: Int
    public let enableRateLimiting: Bool
    public let rateLimitRequests: Int
    public let rateLimitWindow: Int
    
    // MARK: - LLM Configuration
    public let defaultModel: String
    public let ollamaBaseURL: String
    public let requestTimeout: TimeInterval
    public let resourceTimeout: TimeInterval
    public let systemPrompt: String
    
    // MARK: - Logging Configuration
    public let logLevel: LogLevel
    public let enableAuditLogging: Bool
    
    public init(
        listenAddress: String = Constants.defaultListenAddress,
        telnetPort: Int = Constants.defaultTelnetPort,
        controlHost: String = Constants.defaultControlHost,
        controlPort: Int = Constants.defaultControlPort,
        width: Int = Constants.defaultWidth,
        wrap: Bool = true,
        maxInputLength: Int = Constants.defaultMaxInputLength,
        enableRateLimiting: Bool = true,
        rateLimitRequests: Int = Constants.defaultRateLimitRequests,
        rateLimitWindow: Int = Constants.defaultRateLimitWindow,
        defaultModel: String = Constants.defaultModel,
        ollamaBaseURL: String = Constants.defaultOllamaBaseURL,
        requestTimeout: TimeInterval = Constants.defaultRequestTimeout,
        resourceTimeout: TimeInterval = Constants.defaultResourceTimeout,
        systemPrompt: String = Constants.defaultSystemPrompt,
        logLevel: LogLevel = .info,
        enableAuditLogging: Bool = true
    ) {
        self.listenAddress = listenAddress
        self.telnetPort = telnetPort
        self.controlHost = controlHost
        self.controlPort = controlPort
        self.width = width
        self.wrap = wrap
        self.maxInputLength = maxInputLength
        self.enableRateLimiting = enableRateLimiting
        self.rateLimitRequests = rateLimitRequests
        self.rateLimitWindow = rateLimitWindow
        self.defaultModel = defaultModel
        self.ollamaBaseURL = ollamaBaseURL
        self.requestTimeout = requestTimeout
        self.resourceTimeout = resourceTimeout
        self.systemPrompt = systemPrompt
        self.logLevel = logLevel
        self.enableAuditLogging = enableAuditLogging
    }
    
    /// Loads configuration from file and environment variables
    public static func load() -> SharedConfiguration {
        // Try to load from config file first
        if let config = loadFromFile() {
            return validateConfiguration(config)
        }
        
        // Fall back to environment variables
        return validateConfiguration(loadFromEnvironment())
    }
    
    /// Loads configuration from config file
    private static func loadFromFile() -> SharedConfiguration? {
        let configPaths = [
            Constants.configPath,
            "config.json"
        ]
        
        for path in configPaths {
            if let config = loadFromPath(path) {
                return config
            }
        }
        
        return nil
    }
    
    /// Loads configuration from specific file path
    private static func loadFromPath(_ path: String) -> SharedConfiguration? {
        let url = URL(fileURLWithPath: path)
        
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return parseJSON(json)
    }
    
    /// Loads configuration from environment variables
    private static func loadFromEnvironment() -> SharedConfiguration {
        return SharedConfiguration(
            listenAddress: ProcessInfo.processInfo.environment["C64GPT_LISTEN_ADDRESS"] ?? Constants.defaultListenAddress,
            telnetPort: Int(ProcessInfo.processInfo.environment["C64GPT_TELNET_PORT"] ?? "\(Constants.defaultTelnetPort)") ?? Constants.defaultTelnetPort,
            controlHost: ProcessInfo.processInfo.environment["C64GPT_CONTROL_HOST"] ?? Constants.defaultControlHost,
            controlPort: Int(ProcessInfo.processInfo.environment["C64GPT_CONTROL_PORT"] ?? "\(Constants.defaultControlPort)") ?? Constants.defaultControlPort,
            width: Int(ProcessInfo.processInfo.environment["C64GPT_WIDTH"] ?? "\(Constants.defaultWidth)") ?? Constants.defaultWidth,
            wrap: ProcessInfo.processInfo.environment["C64GPT_WRAP"] != "false",
            maxInputLength: Int(ProcessInfo.processInfo.environment["C64GPT_MAX_INPUT_LENGTH"] ?? "\(Constants.defaultMaxInputLength)") ?? Constants.defaultMaxInputLength,
            enableRateLimiting: ProcessInfo.processInfo.environment["C64GPT_ENABLE_RATE_LIMITING"] != "false",
            rateLimitRequests: Int(ProcessInfo.processInfo.environment["C64GPT_RATE_LIMIT_REQUESTS"] ?? "\(Constants.defaultRateLimitRequests)") ?? Constants.defaultRateLimitRequests,
            rateLimitWindow: Int(ProcessInfo.processInfo.environment["C64GPT_RATE_LIMIT_WINDOW"] ?? "\(Constants.defaultRateLimitWindow)") ?? Constants.defaultRateLimitWindow,
            defaultModel: ProcessInfo.processInfo.environment["C64GPT_DEFAULT_MODEL"] ?? Constants.defaultModel,
            ollamaBaseURL: ProcessInfo.processInfo.environment["C64GPT_OLLAMA_BASE_URL"] ?? Constants.defaultOllamaBaseURL,
            requestTimeout: TimeInterval(ProcessInfo.processInfo.environment["C64GPT_REQUEST_TIMEOUT"] ?? "\(Constants.defaultRequestTimeout)") ?? Constants.defaultRequestTimeout,
            resourceTimeout: TimeInterval(ProcessInfo.processInfo.environment["C64GPT_RESOURCE_TIMEOUT"] ?? "\(Constants.defaultResourceTimeout)") ?? Constants.defaultResourceTimeout,
            systemPrompt: ProcessInfo.processInfo.environment["C64GPT_SYSTEM_PROMPT"] ?? Constants.defaultSystemPrompt,
            logLevel: LogLevel(rawValue: ProcessInfo.processInfo.environment["C64GPT_LOG_LEVEL"] ?? "info") ?? .info,
            enableAuditLogging: ProcessInfo.processInfo.environment["C64GPT_ENABLE_AUDIT_LOGGING"] != "false"
        )
    }
    
    /// Parses JSON configuration
    private static func parseJSON(_ json: [String: Any]) -> SharedConfiguration {
        return SharedConfiguration(
            listenAddress: json["listenAddress"] as? String ?? Constants.defaultListenAddress,
            telnetPort: json["telnetPort"] as? Int ?? Constants.defaultTelnetPort,
            controlHost: json["controlHost"] as? String ?? Constants.defaultControlHost,
            controlPort: json["controlPort"] as? Int ?? Constants.defaultControlPort,
            width: json["width"] as? Int ?? Constants.defaultWidth,
            wrap: json["wrap"] as? Bool ?? true,
            maxInputLength: json["maxInputLength"] as? Int ?? Constants.defaultMaxInputLength,
            enableRateLimiting: json["enableRateLimiting"] as? Bool ?? true,
            rateLimitRequests: json["rateLimitRequests"] as? Int ?? Constants.defaultRateLimitRequests,
            rateLimitWindow: json["rateLimitWindow"] as? Int ?? Constants.defaultRateLimitWindow,
            defaultModel: json["defaultModel"] as? String ?? Constants.defaultModel,
            ollamaBaseURL: json["ollamaBaseURL"] as? String ?? Constants.defaultOllamaBaseURL,
            requestTimeout: json["requestTimeout"] as? TimeInterval ?? Constants.defaultRequestTimeout,
            resourceTimeout: json["resourceTimeout"] as? TimeInterval ?? Constants.defaultResourceTimeout,
            systemPrompt: json["systemPrompt"] as? String ?? Constants.defaultSystemPrompt,
            logLevel: LogLevel(rawValue: json["logLevel"] as? String ?? "info") ?? .info,
            enableAuditLogging: json["enableAuditLogging"] as? Bool ?? true
        )
    }
    
    /// Validates configuration values and provides defaults for invalid values
    static func validateConfiguration(_ config: SharedConfiguration) -> SharedConfiguration {
        // Validate port numbers
        let validTelnetPort = (1...65535).contains(config.telnetPort) ? config.telnetPort : Constants.defaultTelnetPort
        let validControlPort = (1...65535).contains(config.controlPort) ? config.controlPort : Constants.defaultControlPort
        
        // Validate width
        let validWidth = (10...200).contains(config.width) ? config.width : Constants.defaultWidth
        
        // Validate timeouts
        let validRequestTimeout = config.requestTimeout > 0 ? config.requestTimeout : Constants.defaultRequestTimeout
        let validResourceTimeout = config.resourceTimeout > 0 ? config.resourceTimeout : Constants.defaultResourceTimeout
        
        // Validate rate limiting
        let validRateLimitRequests = config.rateLimitRequests > 0 ? config.rateLimitRequests : Constants.defaultRateLimitRequests
        let validRateLimitWindow = config.rateLimitWindow > 0 ? config.rateLimitWindow : Constants.defaultRateLimitWindow
        
        // Validate input length
        let validMaxInputLength = (100...10000).contains(config.maxInputLength) ? config.maxInputLength : Constants.defaultMaxInputLength
        
        return SharedConfiguration(
            listenAddress: config.listenAddress,
            telnetPort: validTelnetPort,
            controlHost: config.controlHost,
            controlPort: validControlPort,
            width: validWidth,
            wrap: config.wrap,
            maxInputLength: validMaxInputLength,
            enableRateLimiting: config.enableRateLimiting,
            rateLimitRequests: validRateLimitRequests,
            rateLimitWindow: validRateLimitWindow,
            defaultModel: config.defaultModel.isEmpty ? Constants.defaultModel : config.defaultModel,
            ollamaBaseURL: config.ollamaBaseURL.isEmpty ? Constants.defaultOllamaBaseURL : config.ollamaBaseURL,
            requestTimeout: validRequestTimeout,
            resourceTimeout: validResourceTimeout,
            systemPrompt: config.systemPrompt.isEmpty ? Constants.defaultSystemPrompt : config.systemPrompt,
            logLevel: config.logLevel,
            enableAuditLogging: config.enableAuditLogging
        )
    }
    
    /// Saves configuration to file
    public func save(to path: String) throws {
        let json: [String: Any] = [
            "listenAddress": listenAddress,
            "telnetPort": telnetPort,
            "controlHost": controlHost,
            "controlPort": controlPort,
            "width": width,
            "wrap": wrap,
            "maxInputLength": maxInputLength,
            "enableRateLimiting": enableRateLimiting,
            "rateLimitRequests": rateLimitRequests,
            "rateLimitWindow": rateLimitWindow,
            "defaultModel": defaultModel,
            "ollamaBaseURL": ollamaBaseURL,
            "requestTimeout": requestTimeout,
            "resourceTimeout": resourceTimeout,
            "systemPrompt": systemPrompt,
            "logLevel": logLevel.rawValue,
            "enableAuditLogging": enableAuditLogging
        ]
        
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: URL(fileURLWithPath: path))
    }
}

// MARK: - Log Level
public enum LogLevel: String, CaseIterable, Codable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    
    public var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }
}
