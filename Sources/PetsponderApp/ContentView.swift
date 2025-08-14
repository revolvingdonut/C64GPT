import SwiftUI
import TelnetGateway

struct ContentView: View {
    @StateObject private var serverManager = ServerManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("C64GPT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Local LLM for Commodore 64")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // Server Status
            VStack(spacing: 16) {
                HStack {
                    Circle()
                        .fill(serverManager.isRunning ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(serverManager.isRunning ? "Server Running" : "Server Stopped")
                        .font(.headline)
                    
                    Spacer()
                }
                
                if serverManager.isRunning {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Telnet Port:")
                            Spacer()
                            Text("6400")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Connect with:")
                            Spacer()
                            Text("telnet localhost 6400")
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            
            // Control Buttons
            HStack(spacing: 16) {
                Button(action: {
                    if serverManager.isRunning {
                        serverManager.stopServer()
                    } else {
                        serverManager.startServer()
                    }
                }) {
                    HStack {
                        Image(systemName: serverManager.isRunning ? "stop.circle.fill" : "play.circle.fill")
                        Text(serverManager.isRunning ? "Stop Server" : "Start Server")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(serverManager.isRunning ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(serverManager.isStarting)
                
                Button(action: {
                    // Copy connection command to clipboard
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("telnet localhost 6400", forType: .string)
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Command")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!serverManager.isRunning)
            }
            .padding(.horizontal, 20)
            
            // Status Messages
            if !serverManager.statusMessage.isEmpty {
                Text(serverManager.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 4) {
                Text("Phase 0 - Basic Telnet Server")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("LLM integration coming soon!")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 500)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

class ServerManager: ObservableObject {
    @Published var isRunning = false
    @Published var isStarting = false
    @Published var statusMessage = ""
    
    private var serverProcess: Process?
    
    func startServer() {
        isStarting = true
        statusMessage = "Starting server..."
        
        // For now, just simulate server start
        // In the real implementation, this would launch the PetsponderDaemon process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isRunning = true
            self.isStarting = false
            self.statusMessage = "Server started successfully!"
            
            // Clear status message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.statusMessage == "Server started successfully!" {
                    self.statusMessage = ""
                }
            }
        }
    }
    
    func stopServer() {
        statusMessage = "Stopping server..."
        
        // For now, just simulate server stop
        // In the real implementation, this would terminate the PetsponderDaemon process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isRunning = false
            self.statusMessage = "Server stopped."
            
            // Clear status message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.statusMessage == "Server stopped." {
                    self.statusMessage = ""
                }
            }
        }
    }
}

// #Preview {
//     ContentView()
// }
