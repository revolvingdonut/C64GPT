import SwiftUI
import TelnetGateway
import Core
import UIComponents

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
                    StatusIndicator(
                        isActive: serverManager.isRunning,
                        activeText: "Server Running",
                        inactiveText: "Server Stopped",
                        size: 12
                    )
                    
                    Spacer()
                }
                
                if serverManager.isRunning {
                    ConnectionInfo()
                }
            }
            .padding(.horizontal, 20)
            
            // Control Buttons
            HStack(spacing: 16) {
                ActionButton(
                    title: serverManager.isRunning ? "Stop Server" : "Start Server",
                    icon: serverManager.isRunning ? "stop.circle.fill" : "play.circle.fill",
                    action: {
                        if serverManager.isRunning {
                            serverManager.stopServer()
                        } else {
                            serverManager.startServer()
                        }
                    },
                    isEnabled: !serverManager.isStarting,
                    backgroundColor: serverManager.isRunning ? .red : .green,
                    isLoading: serverManager.isStarting
                )
                
                ActionButton(
                    title: "Copy Command",
                    icon: "doc.on.doc",
                    action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(Constants.telnetCommand, forType: .string)
                    },
                    isEnabled: serverManager.isRunning,
                    backgroundColor: .blue
                )
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



// #Preview {
//     ContentView()
// }
