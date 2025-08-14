import Foundation
import TelnetGateway
import SystemPackage
import NIO

/// Main entry point for the Petsponder daemon
@main
struct PetsponderDaemon {
    static func main() async {
        print("🚀 Starting C64GPT Telnet Server...")
        
        // Create server configuration
        let config = ServerConfig(
            listenAddress: "0.0.0.0",
            telnetPort: 6400,
            renderMode: .petscii,
            width: 40
        )
        
        // Set up signal handling for graceful shutdown
        signal(SIGINT) { _ in
            print("\n🛑 Shutting down server gracefully...")
            print("✅ Cleanup complete")
            exit(0)
        }
        
        do {
            // Create and start the Telnet server
            let server = try TelnetServer(config: config)
            let channel = try server.start()
            
            print("✅ Server is running!")
            print("📍 Listening on \(config.listenAddress):\(config.telnetPort)")
            print("🎨 Render mode: \(config.renderMode)")
            print("📏 Width: \(config.width)")
            print("")
            print("💡 Connect with: nc localhost \(config.telnetPort)")
            print("💡 Or use a PETSCII terminal like SyncTerm")
            print("")
            print("🛑 Press Ctrl+C to stop the server")
            
            // Wait for the server to be closed
            try await channel.closeFuture.get()
            
            print("✅ Server stopped gracefully")
            
        } catch {
            print("❌ Failed to start server: \(error)")
            exit(1)
        }
    }
}
