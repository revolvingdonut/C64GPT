import Foundation
import Core

/// Simple logging system for C64GPT
public class Logger {
    public static let shared = Logger()
    
    private var logLevel: Core.LogLevel = .info
    private var enableAuditLogging: Bool = true
    private var logFile: URL?
    
    private init() {}
    
    /// Configure the logger
    public func configure(level: Core.LogLevel, enableAuditLogging: Bool = true, logFile: URL? = nil) {
        self.logLevel = level
        self.enableAuditLogging = enableAuditLogging
        self.logFile = logFile
    }
    
    /// Log a debug message
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }
    
    /// Log an info message
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }
    
    /// Log an error message
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }
    
    /// Log an audit message (for security events)
    public func audit(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if enableAuditLogging {
            log(.info, "[AUDIT] \(message)", file: file, function: function, line: line)
        }
    }
    
    /// Internal logging method
    private func log(_ level: Core.LogLevel, _ message: String, file: String, function: String, line: Int) {
        // Check if we should log this level
        guard level.priority >= logLevel.priority else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(timestamp)] [\(level.rawValue.uppercased())] [\(fileName):\(line)] \(function): \(message)"
        
        // Print to console
        print(logMessage)
        
        // Write to log file if configured
        if let logFile = logFile {
            writeToFile(logMessage, to: logFile)
        }
    }
    
    /// Write log message to file
    private func writeToFile(_ message: String, to url: URL) {
        let logMessage = message + "\n"
        
        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try "".write(to: url, atomically: true, encoding: .utf8)
            }
            
            let handle = try FileHandle(forWritingTo: url)
            handle.seekToEndOfFile()
            handle.write(logMessage.data(using: .utf8) ?? Data())
            handle.closeFile()
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
}

/// Convenience methods for quick logging
/// @deprecated Use ErrorHandler from Core module for centralized error handling
public func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, file: file, function: function, line: line)
}

public func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, file: file, function: function, line: line)
}

public func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, file: file, function: function, line: line)
}

public func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, file: file, function: function, line: line)
}

public func logAudit(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.audit(message, file: file, function: function, line: line)
}
