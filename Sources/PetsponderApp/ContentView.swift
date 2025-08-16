import SwiftUI
import TelnetGateway
import Core
import UIComponents

struct ContentView: View {
    @StateObject private var serverManager = ServerManager()
    
    var body: some View {
        VStack(spacing: 16) {
            // Compact Header
            VStack(spacing: 6) {
                Text("C64GPT")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Local LLM for Commodore 64")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
            
            // Compact Server Status
            VStack(spacing: 12) {
                HStack {
                    StatusIndicator(
                        isActive: serverManager.isRunning,
                        activeText: "Server Running",
                        inactiveText: "Server Stopped",
                        size: 8
                    )
                    
                    Spacer()
                }
                
                if serverManager.isRunning {
                    ContentViewConnectionInfo()
                }
            }
            .padding(.horizontal, 16)
            
            // Compact Control Buttons
            VStack(spacing: 8) {
                CompactActionButton(
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
                    isLoading: serverManager.isStarting
                )
                
                CompactActionButton(
                    title: "Copy Command",
                    icon: "doc.on.doc",
                    action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(Constants.telnetCommand, forType: .string)
                    },
                    isEnabled: serverManager.isRunning
                )
            }
            .padding(.horizontal, 16)
            
            // Compact Status Messages
            if !serverManager.statusMessage.isEmpty {
                ContentViewAlertBanner(
                    title: "Server Status",
                    message: serverManager.statusMessage,
                    type: serverManager.isRunning ? .success : .warning
                )
            }
            
            Spacer()
            
            // Compact Footer
            VStack(spacing: 2) {
                Text("Phase 0 - Basic Telnet Server")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("LLM integration coming soon!")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)
        }
        .frame(width: 320, height: 400)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - ContentView-specific Compact Components

struct ContentViewConnectionInfo: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Telnet Port", systemImage: "network")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(.darkGray))
                
                Spacer()
                
                Text("6400")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray)
                    )
            }
            
            HStack {
                Label("Connection", systemImage: "terminal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(.darkGray))
                
                Spacer()
                
                Text(Constants.telnetCommand)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Color(.darkGray))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                    )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

struct ContentViewAlertBanner: View {
    let title: String
    let message: String
    let type: AlertBanner.AlertType
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: type.icon)
                .font(.system(size: 10))
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(type.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

// #Preview {
//     ContentView()
// }
