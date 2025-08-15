import Foundation
import TelnetGateway
import SystemPackage
import NIO

/// Main entry point for the Petsponder daemon
@main
struct PetsponderDaemon {
    static func main() async {
        // Load configuration
        let config = Configuration.load()
        
        // Configure logger
        Logger.shared.configure(
            level: config.logLevel,
            enableAuditLogging: config.enableAuditLogging,
            logFile: URL(fileURLWithPath: "c64gpt.log")
        )
        
        logInfo("🚀 Starting C64GPT Telnet Server...")
        
        // Create server configuration
        let serverConfig = ServerConfig(
            listenAddress: config.listenAddress,
            telnetPort: config.telnetPort,
            controlHost: config.controlHost,
            controlPort: config.controlPort,
            renderMode: config.renderMode,
            width: config.width,
            wrap: config.wrap,
            maxInputLength: config.maxInputLength,
            defaultModel: config.defaultModel
        )
        
        // Set up signal handling for graceful shutdown
        signal(SIGINT) { _ in
            logInfo("🛑 Shutting down server gracefully...")
            logInfo("✅ Cleanup complete")
            exit(0)
        }
        
        do {
            // Create and start the Telnet server
            let server = try TelnetServer(config: serverConfig)
            let channel = try server.start()
            
            logInfo("✅ Server is running!")
            logInfo("📍 Listening on \(config.listenAddress):\(config.telnetPort)")
            logInfo("🎨 Render mode: \(config.renderMode)")
            logInfo("📏 Width: \(config.width)")
            logInfo("🔒 Security: Rate limiting \(config.enableRateLimiting ? "enabled" : "disabled")")
            logInfo("📝 Logging: Level \(config.logLevel.rawValue)")
            logInfo("")
            logInfo("💡 Connect with: nc localhost \(config.telnetPort)")
            logInfo("💡 Or use a PETSCII terminal like SyncTerm")
            logInfo("")
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
