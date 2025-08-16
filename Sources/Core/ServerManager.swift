import Foundation
import SwiftUI

@MainActor
public class ServerManager: ObservableObject {
    @Published public var isRunning = false
    @Published public var isStarting = false
    @Published public var statusMessage = ""
    
    private var serverProcess: Process?
    private var serverPID: Int32?
    private var statusCheckTimer: Timer?
    
    public init() {}
    
    public func startServer() {
        isStarting = true
        statusMessage = Constants.serverStartingMessage
        
        // Kill any existing server processes first
        killExistingServerProcesses()
        
        // Launch the PetsponderDaemon process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["run", "PetsponderDaemon"]
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        // Set up pipe for output
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Handle process termination
        process.terminationHandler = { [weak self] process in
            Task { @MainActor in
                self?.handleServerTermination(process)
            }
        }
        
        do {
            try process.run()
            self.serverProcess = process
            self.serverPID = process.processIdentifier
            
            // Check if process started successfully
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                Task { @MainActor in
                    if process.isRunning {
                        self.isRunning = true
                        self.isStarting = false
                        self.statusMessage = Constants.serverStartedMessage
                        self.startStatusChecking()
                        
                        // Clear status message after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            Task { @MainActor in
                                if self.statusMessage == Constants.serverStartedMessage {
                                    self.statusMessage = ""
                                }
                            }
                        }
                    } else {
                        self.isStarting = false
                        self.statusMessage = "Failed to start server"
                        self.serverProcess = nil
                        self.serverPID = nil
                    }
                }
            }
        } catch {
            isStarting = false
            statusMessage = ErrorHandler.shared.handleServerError(error)
            serverProcess = nil
            serverPID = nil
        }
    }
    
    public func stopServer() {
        statusMessage = Constants.serverStoppingMessage
        
        // First try to stop the managed process
        if let process = serverProcess, process.isRunning {
            process.terminate()
            
            // Give it a moment to terminate gracefully
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Task { @MainActor in
                    if !process.isRunning {
                        self.handleServerStopped()
                    } else {
                        // Force kill if it didn't terminate gracefully
                        process.interrupt()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            Task { @MainActor in
                                if !process.isRunning {
                                    self.handleServerStopped()
                                } else {
                                    // Final force kill
                                    process.terminate()
                                    self.handleServerStopped()
                                }
                            }
                        }
                    }
                }
            }
        } else {
            // Try to kill by PID if we have it
            if serverPID != nil {
                killExistingServerProcesses()
                handleServerStopped()
            } else {
                // Fallback: kill any server processes
                killExistingServerProcesses()
                handleServerStopped()
            }
        }
    }
    
    private func handleServerTermination(_ process: Process) {
        isRunning = false
        isStarting = false
        serverProcess = nil
        serverPID = nil
        stopStatusChecking()
        
        if process.terminationStatus == 0 {
            statusMessage = "Server stopped gracefully."
        } else {
            statusMessage = "Server stopped with exit code: \(process.terminationStatus)"
        }
        
        // Clear status message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            Task { @MainActor in
                if self.statusMessage.contains("Server stopped") {
                    self.statusMessage = ""
                }
            }
        }
    }
    
    private func handleServerStopped() {
        isRunning = false
        isStarting = false
        serverProcess = nil
        serverPID = nil
        stopStatusChecking()
        statusMessage = Constants.serverStoppedMessage
        
        // Clear status message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            Task { @MainActor in
                if self.statusMessage == Constants.serverStoppedMessage {
                    self.statusMessage = ""
                }
            }
        }
    }
    
    private func killExistingServerProcesses() {
        // Kill any existing PetsponderDaemon processes
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        task.arguments = ["-f", "PetsponderDaemon"]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            // Ignore errors - process might not exist
        }
        
        // Also try to kill by PID if we have a PID file
        let pidFile = FileManager.default.currentDirectoryPath + "/" + Constants.pidPath
        if let pidData = try? Data(contentsOf: URL(fileURLWithPath: pidFile)),
           let pidString = String(data: pidData, encoding: .utf8),
           let pid = Int32(pidString) {
            
            let killTask = Process()
            killTask.executableURL = URL(fileURLWithPath: "/bin/kill")
            killTask.arguments = ["\(pid)"]
            
            do {
                try killTask.run()
                killTask.waitUntilExit()
            } catch {
                // Ignore errors
            }
            
            // Remove PID file
            try? FileManager.default.removeItem(atPath: pidFile)
        }
    }
    
    private func startStatusChecking() {
        statusCheckTimer?.invalidate()
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkServerStatus()
            }
        }
    }
    
    private func stopStatusChecking() {
        statusCheckTimer?.invalidate()
        statusCheckTimer = nil
    }
    
    private func checkServerStatus() {
        guard let process = serverProcess else {
            isRunning = false
            stopStatusChecking()
            return
        }
        
        if !process.isRunning {
            handleServerTermination(process)
            stopStatusChecking()
        }
    }
    
    deinit {
        statusCheckTimer?.invalidate()
        statusCheckTimer = nil
        if let process = serverProcess, process.isRunning {
            process.terminate()
        }
    }
}
