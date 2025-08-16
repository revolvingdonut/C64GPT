import Foundation
import TelnetGateway
import Core
import SystemPackage
import NIO

/// Main entry point for the Petsponder daemon
@main
struct PetsponderDaemon {
    static func main() async {
        // Load configuration
        let config = SharedConfiguration.load()
        
        // Configure logger
        Logger.shared.configure(
            level: config.logLevel,
            enableAuditLogging: config.enableAuditLogging,
            logFile: URL(fileURLWithPath: Constants.logPath)
        )
        
        logInfo("🚀 Starting C64GPT Telnet Server...")
        
        // Use shared configuration directly
        let serverConfig = config
        
        // Set up signal handling for graceful shutdown
        signal(SIGINT) { _ in
            logInfo("🛑 Shutting down server gracefully...")
            exit(0)
        }
        
        signal(SIGTERM) { _ in
            logInfo("🛑 Received SIGTERM, shutting down server gracefully...")
            exit(0)
        }
        
        do {
            // Create and start the Telnet server
            let server = try TelnetServer(config: serverConfig)
            let channel = try server.start()
            
                    logInfo("✅ Server is running on \(config.listenAddress):\(config.telnetPort)")
        logInfo("📏 Width: \(config.width), Rate limiting: \(config.enableRateLimiting ? "enabled" : "disabled")")
        logInfo("💡 Connect with: \(Constants.telnetCommand)")
        logInfo("🛑 Press Ctrl+C to stop the server")
            
            // Wait for the server to be closed
            try await channel.closeFuture.get()
            
            logInfo("✅ Server stopped gracefully")
            
        } catch {
            logError("❌ Failed to start server: \(error)")
            exit(1)
        }
    }
}
