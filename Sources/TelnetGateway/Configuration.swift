import Foundation

/// Configuration management for C64GPT
public struct Configuration {
    
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
    
    // MARK: - Logging Configuration
    public let logLevel: LogLevel
    public let enableAuditLogging: Bool
    
    public init(
        listenAddress: String = "0.0.0.0",
        telnetPort: Int = 6400,
        controlHost: String = "127.0.0.1",
        controlPort: Int = 4333,
        width: Int = 40,
        wrap: Bool = true,
        maxInputLength: Int = 1000,
        enableRateLimiting: Bool = true,
        rateLimitRequests: Int = 100,
        rateLimitWindow: Int = 60,
        defaultModel: String = "gemma2:2b",
        ollamaBaseURL: String = "http://localhost:11434",
        requestTimeout: TimeInterval = 30.0,
        resourceTimeout: TimeInterval = 300.0,
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
        self.logLevel = logLevel
        self.enableAuditLogging = enableAuditLogging
    }
    
    /// Loads configuration from file and environment variables
    public static func load() -> Configuration {
        // Try to load from config file first
        if let config = loadFromFile() {
            return validateConfiguration(config)
        }
        
        // Fall back to environment variables
        return validateConfiguration(loadFromEnvironment())
    }
    
    /// Loads configuration from config file
    private static func loadFromFile() -> Configuration? {
        let configPaths = [
            "Config/config.json",
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
    private static func loadFromPath(_ path: String) -> Configuration? {
        let url = URL(fileURLWithPath: path)
        
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return parseJSON(json)
    }
    
    /// Loads configuration from environment variables
    private static func loadFromEnvironment() -> Configuration {
        return Configuration(
            listenAddress: ProcessInfo.processInfo.environment["C64GPT_LISTEN_ADDRESS"] ?? "0.0.0.0",
            telnetPort: Int(ProcessInfo.processInfo.environment["C64GPT_TELNET_PORT"] ?? "6400") ?? 6400,
            controlHost: ProcessInfo.processInfo.environment["C64GPT_CONTROL_HOST"] ?? "127.0.0.1",
            controlPort: Int(ProcessInfo.processInfo.environment["C64GPT_CONTROL_PORT"] ?? "4333") ?? 4333,

            width: Int(ProcessInfo.processInfo.environment["C64GPT_WIDTH"] ?? "40") ?? 40,
            wrap: ProcessInfo.processInfo.environment["C64GPT_WRAP"] != "false",
            maxInputLength: Int(ProcessInfo.processInfo.environment["C64GPT_MAX_INPUT_LENGTH"] ?? "1000") ?? 1000,
            enableRateLimiting: ProcessInfo.processInfo.environment["C64GPT_ENABLE_RATE_LIMITING"] != "false",
            rateLimitRequests: Int(ProcessInfo.processInfo.environment["C64GPT_RATE_LIMIT_REQUESTS"] ?? "100") ?? 100,
            rateLimitWindow: Int(ProcessInfo.processInfo.environment["C64GPT_RATE_LIMIT_WINDOW"] ?? "60") ?? 60,
            defaultModel: ProcessInfo.processInfo.environment["C64GPT_DEFAULT_MODEL"] ?? "gemma2:2b",
            ollamaBaseURL: ProcessInfo.processInfo.environment["C64GPT_OLLAMA_BASE_URL"] ?? "http://localhost:11434",
            requestTimeout: TimeInterval(ProcessInfo.processInfo.environment["C64GPT_REQUEST_TIMEOUT"] ?? "30.0") ?? 30.0,
            resourceTimeout: TimeInterval(ProcessInfo.processInfo.environment["C64GPT_RESOURCE_TIMEOUT"] ?? "300.0") ?? 300.0,
            logLevel: LogLevel(rawValue: ProcessInfo.processInfo.environment["C64GPT_LOG_LEVEL"] ?? "info") ?? .info,
            enableAuditLogging: ProcessInfo.processInfo.environment["C64GPT_ENABLE_AUDIT_LOGGING"] != "false"
        )
    }
    
    /// Parses JSON configuration
    private static func parseJSON(_ json: [String: Any]) -> Configuration {
        return Configuration(
            listenAddress: json["listenAddress"] as? String ?? "0.0.0.0",
            telnetPort: json["telnetPort"] as? Int ?? 6400,
            controlHost: json["controlHost"] as? String ?? "127.0.0.1",
            controlPort: json["controlPort"] as? Int ?? 4333,

            width: json["width"] as? Int ?? 40,
            wrap: json["wrap"] as? Bool ?? true,
            maxInputLength: json["maxInputLength"] as? Int ?? 1000,
            enableRateLimiting: json["enableRateLimiting"] as? Bool ?? true,
            rateLimitRequests: json["rateLimitRequests"] as? Int ?? 100,
            rateLimitWindow: json["rateLimitWindow"] as? Int ?? 60,
            defaultModel: json["defaultModel"] as? String ?? "gemma2:2b",
            ollamaBaseURL: json["ollamaBaseURL"] as? String ?? "http://localhost:11434",
            requestTimeout: json["requestTimeout"] as? TimeInterval ?? 30.0,
            resourceTimeout: json["resourceTimeout"] as? TimeInterval ?? 300.0,
            logLevel: LogLevel(rawValue: json["logLevel"] as? String ?? "info") ?? .info,
            enableAuditLogging: json["enableAuditLogging"] as? Bool ?? true
        )
    }
    
    /// Validates configuration values and provides defaults for invalid values
    static func validateConfiguration(_ config: Configuration) -> Configuration {
        // Validate port numbers
        let validTelnetPort = (1...65535).contains(config.telnetPort) ? config.telnetPort : 6400
        let validControlPort = (1...65535).contains(config.controlPort) ? config.controlPort : 4333
        
        // Validate width
        let validWidth = (10...200).contains(config.width) ? config.width : 40
        
        // Validate timeouts
        let validRequestTimeout = config.requestTimeout > 0 ? config.requestTimeout : 30.0
        let validResourceTimeout = config.resourceTimeout > 0 ? config.resourceTimeout : 300.0
        
        // Validate rate limiting
        let validRateLimitRequests = config.rateLimitRequests > 0 ? config.rateLimitRequests : 100
        let validRateLimitWindow = config.rateLimitWindow > 0 ? config.rateLimitWindow : 60
        
        // Validate input length
        let validMaxInputLength = (100...10000).contains(config.maxInputLength) ? config.maxInputLength : 1000
        
        return Configuration(
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
            defaultModel: config.defaultModel.isEmpty ? "gemma2:2b" : config.defaultModel,
            ollamaBaseURL: config.ollamaBaseURL.isEmpty ? "http://localhost:11434" : config.ollamaBaseURL,
            requestTimeout: validRequestTimeout,
            resourceTimeout: validResourceTimeout,
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
            "logLevel": logLevel.rawValue,
            "enableAuditLogging": enableAuditLogging
        ]
        
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: URL(fileURLWithPath: path))
    }
}

/// Log levels for configuration
public enum LogLevel: String, CaseIterable {
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
