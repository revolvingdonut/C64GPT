import Foundation
import TelnetGateway
import SystemPackage

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
            
            // Set up signal handling for graceful shutdown
            signal(SIGINT) { _ in
                print("\n🛑 Shutting down server...")
                exit(0)
            }
            
            // Wait for the server to be closed
            try await channel.closeFuture.get()
            
            print("✅ Server stopped gracefully")
            
        } catch {
            print("❌ Failed to start server: \(error)")
            exit(1)
        }
    }
}
