import Foundation
import TelnetGateway

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
        
        do {
            // Create and start the Telnet server
            let server = try TelnetServer(config: config)
            let channel = try server.start()
            
            print("✅ Server is running!")
            print("📡 Connect with: telnet localhost 6400")
            print("🛑 Press Ctrl+C to stop the server")
            
            // Wait for the server to be closed
            try await channel.closeFuture.get()
            
        } catch {
            print("❌ Failed to start server: \(error)")
            exit(1)
        }
    }
}
