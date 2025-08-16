import SwiftUI
import OllamaClient
import TelnetGateway
import Core
import UIComponents

struct UnifiedManagementView: View {
    @StateObject private var serverManager = ServerManager()
    @StateObject private var llmViewModel = LLMManagementViewModel()
    @State private var selectedTab = 0
    @State private var showingModelDownload = false
    @State private var showingSystemPromptEditor = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var modelToRemove: String?
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("C64GPT Management")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(selectedTab == 0 ? "Server Management" : "LLM Model Management")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Compact Status Badge
                    StatusIndicator(
                        isActive: serverManager.isRunning && llmViewModel.isConnected,
                        activeText: "Ready",
                        inactiveText: "Not Ready",
                        size: 6
                    )
                }
                
                // Compact Tab Bar
                HStack(spacing: 4) {
                    TabButton(
                        title: "Server",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "Models",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
            )
            
            // Tab Content
            if selectedTab == 0 {
                ServerManagementTab(serverManager: serverManager)
            } else {
                LLMManagementTab(
                    viewModel: llmViewModel,
                    serverManager: serverManager,
                    showingModelDownload: $showingModelDownload,
                    showingSystemPromptEditor: $showingSystemPromptEditor,
                    modelToRemove: $modelToRemove,
                    showingRemoveConfirmation: $showingRemoveConfirmation
                )
            }
        }
        .background(Color.black.opacity(0.1))
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            Task {
                await llmViewModel.refreshModels()
            }
        }
        .sheet(isPresented: $showingModelDownload) {
            CompactModelDownloadView(
                isPresented: $showingModelDownload,
                onDownload: { modelName in
                    Task {
                        await llmViewModel.downloadModel(modelName)
                    }
                }
            )
        }
        .sheet(isPresented: $showingSystemPromptEditor) {
            CompactSystemPromptEditorView(
                isPresented: $showingSystemPromptEditor,
                currentPrompt: llmViewModel.systemPrompt,
                onSave: { newPrompt in
                    llmViewModel.updateSystemPrompt(newPrompt)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog(
            "Remove Model",
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove \(modelToRemove ?? "")", role: .destructive) {
                if let modelName = modelToRemove {
                    Task {
                        await llmViewModel.removeModel(modelName)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete the model from your system. This action cannot be undone.")
        }
        .onReceive(llmViewModel.$alertMessage) { message in
            if !message.isEmpty {
                alertMessage = message
                alertTitle = llmViewModel.alertTitle
                showingAlert = true
                llmViewModel.clearAlert()
            }
        }
    }
}

struct ServerManagementTab: View {
    @ObservedObject var serverManager: ServerManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Compact Server Status Card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Server Status")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.darkGray))
                        
                        Text(serverManager.isRunning ? "Running" : "Stopped")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(serverManager.isRunning ? .green : .red)
                    }
                    
                    Spacer()
                    
                    // Compact Status indicator
                    StatusIndicator(
                        isActive: serverManager.isRunning,
                        activeText: "Online",
                        inactiveText: "Offline",
                        size: 8
                    )
                }
                
                // Compact Connection Info
                if serverManager.isRunning {
                    CompactConnectionInfo()
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
                    title: "Copy Connection Command",
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
                CompactAlertBanner(
                    title: "Server Status",
                    message: serverManager.statusMessage,
                    type: serverManager.isRunning ? .success : .warning
                )
            }
            
            Spacer()
        }
    }
}

struct LLMManagementTab: View {
    @ObservedObject var viewModel: LLMManagementViewModel
    @ObservedObject var serverManager: ServerManager
    @Binding var showingModelDownload: Bool
    @Binding var showingSystemPromptEditor: Bool
    @Binding var modelToRemove: String?
    @Binding var showingRemoveConfirmation: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Action Buttons
            HStack(spacing: 8) {
                CompactButton(
                    title: "Refresh",
                    icon: "arrow.clockwise",
                    action: {
                        Task {
                            await viewModel.refreshModels()
                        }
                    },
                    isEnabled: !viewModel.isLoading
                )
                
                CompactButton(
                    title: "Download",
                    icon: "plus.circle.fill",
                    action: {
                        showingModelDownload = true
                    },
                    isEnabled: !viewModel.isConnected || !viewModel.downloadingModel.isEmpty,
                    isPrimary: true
                )
                
                CompactButton(
                    title: "System Prompt",
                    icon: "text.bubble",
                    action: {
                        showingSystemPromptEditor = true
                    }
                )
                
                CompactButton(
                    title: "Restart Server",
                    icon: "arrow.clockwise.circle",
                    action: {
                        if serverManager.isRunning {
                            serverManager.stopServer()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                serverManager.startServer()
                                viewModel.needsServerRestart = false
                            }
                        } else {
                            serverManager.startServer()
                            viewModel.needsServerRestart = false
                        }
                    },
                    isEnabled: !serverManager.isStarting,
                    isWarning: viewModel.needsServerRestart
                )
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Compact Download Progress
            if !viewModel.downloadingModel.isEmpty {
                CompactDownloadProgress(
                    modelName: viewModel.downloadingModel,
                    progress: viewModel.downloadProgress
                )
            }
            
            // Compact Restart Required Notification
            if viewModel.needsServerRestart {
                CompactRestartNotification {
                    if serverManager.isRunning {
                        serverManager.stopServer()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            serverManager.startServer()
                            viewModel.needsServerRestart = false
                        }
                    } else {
                        serverManager.startServer()
                        viewModel.needsServerRestart = false
                    }
                }
            }
            
            // Compact Models Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Installed Models")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if !viewModel.defaultModel.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("Default: \(viewModel.defaultModel)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.15))
                        )
                    }
                }
                .padding(.horizontal, 16)
                
                if viewModel.isLoading {
                    CompactLoadingView(message: "Loading models...")
                } else if viewModel.models.isEmpty {
                    CompactEmptyStateView(
                        onDownload: {
                            showingModelDownload = true
                        },
                        isConnected: viewModel.isConnected
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.models, id: \.name) { model in
                                CompactModelRowView(
                                    model: model,
                                    isDefault: model.name == viewModel.defaultModel,
                                    onSetDefault: {
                                        viewModel.setDefaultModel(model.name)
                                    },
                                    onRemove: {
                                        modelToRemove = model.name
                                        showingRemoveConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Compact UI Components

struct CompactActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let isEnabled: Bool
    let isLoading: Bool
    
    init(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        isLoading: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray)
            )
            .foregroundColor(.white)
        }
        .disabled(!isEnabled || isLoading)
    }
}

struct CompactButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let isEnabled: Bool
    let isPrimary: Bool
    let isWarning: Bool
    
    init(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        isPrimary: Bool = false,
        isWarning: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isEnabled = isEnabled
        self.isPrimary = isPrimary
        self.isWarning = isWarning
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white.opacity(isEnabled ? 0.9 : 0.5))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
            )
        }
        .disabled(!isEnabled)
    }
    
    private var backgroundColor: Color {
        if !isEnabled {
            return Color.gray.opacity(0.3)
        } else if isWarning {
            return Color.red
        } else if isPrimary {
            return Color.gray
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

struct CompactConnectionInfo: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Telnet Port", systemImage: "network")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(.darkGray))
                
                Spacer()
                
                Text("6400")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
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
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(.darkGray))
                
                Spacer()
                
                Text(Constants.telnetCommand)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(.darkGray))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

struct CompactAlertBanner: View {
    let title: String
    let message: String
    let type: AlertBanner.AlertType
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 12))
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(type.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

struct CompactDownloadProgress: View {
    let modelName: String
    let progress: String
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Downloading \(modelName)...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
            
            if !progress.isEmpty {
                Text(progress)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct CompactRestartNotification: View {
    let onRestart: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Server Restart Required")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Configuration changes have been made. Restart the server to apply them.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Restart") {
                onRestart()
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange)
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct CompactLoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 20)
    }
}

struct CompactEmptyStateView: View {
    let onDownload: () -> Void
    let isConnected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 4) {
                Text("No models installed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Download a model to get started with AI conversations")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onDownload) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Download Your First Model")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray)
                )
            }
            .disabled(!isConnected)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 20)
    }
}

struct CompactModelRowView: View {
    let model: OllamaModel
    let isDefault: Bool
    let onSetDefault: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Model Icon
            VStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(isDefault ? .blue : .secondary)
            }
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(isDefault ? Color.blue.opacity(0.1) : Color.gray.opacity(0.2))
            )
            
            // Model Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(model.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if isDefault {
                        Text("DEFAULT")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                            )
                            .foregroundColor(.white)
                    }
                }
                
                HStack(spacing: 8) {
                    Label(formatFileSize(model.size), systemImage: "externaldrive")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Label(formatDate(model.modifiedAt), systemImage: "calendar")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 6) {
                if !isDefault {
                    Button(action: onSetDefault) {
                        HStack(spacing: 2) {
                            Image(systemName: "star")
                                .font(.system(size: 8))
                            Text("Set Default")
                                .font(.system(size: 8, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
                .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
        )
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct CompactModelDownloadView: View {
    @Binding var isPresented: Bool
    let onDownload: (String) -> Void
    
    @State private var modelName = ""
    @State private var popularModels = [
        "gemma2:2b",
        "llama3.2:3b", 
        "llama3.2:1b",
        "mistral:7b",
        "codellama:7b",
        "phi3:mini"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 6) {
                Text("Download Model")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Choose a model to download from Ollama")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Popular Models
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular Models")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(popularModels, id: \.self) { model in
                        Button(action: {
                            modelName = model
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 12))
                                    .foregroundColor(modelName == model ? .white : .blue)
                                
                                Text(model)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(modelName == model ? .white : .white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(modelName == model ? Color.blue : Color.gray.opacity(0.2))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Custom Model Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Or enter custom model name:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("e.g., llama3.2:8b", text: $modelName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 12))
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                .foregroundColor(.white.opacity(0.7))
                
                Button("Download") {
                    if !modelName.isEmpty {
                        onDownload(modelName)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.return)
                .disabled(modelName.isEmpty)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(modelName.isEmpty ? Color.gray : Color.blue)
                )
            }
        }
        .padding(20)
        .frame(width: 400, height: 320)
        .background(Color.gray.opacity(0.1))
    }
}

struct CompactSystemPromptEditorView: View {
    @Binding var isPresented: Bool
    let currentPrompt: String
    let onSave: (String) -> Void
    
    @State private var editedPrompt: String
    @FocusState private var isTextFieldFocused: Bool
    
    init(isPresented: Binding<Bool>, currentPrompt: String, onSave: @escaping (String) -> Void) {
        self._isPresented = isPresented
        self.currentPrompt = currentPrompt
        self.onSave = onSave
        self._editedPrompt = State(initialValue: currentPrompt)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            Text("System Prompt Editor")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            // Text editor
            TextEditor(text: $editedPrompt)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .background(Color.black.opacity(0.3))
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onAppear {
                    isTextFieldFocused = true
                }
            
            // Action buttons
            HStack(spacing: 8) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                .font(.system(size: 11))
                
                Button("Reset") {
                    editedPrompt = "You are a helpful AI assistant. Keep replies concise, friendly, and natural. Respond in plain text without special formatting or markdown."
                }
                .font(.system(size: 11))
                
                Button("Save") {
                    onSave(editedPrompt)
                    isPresented = false
                }
                .keyboardShortcut(.return)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                )
            }
        }
        .padding(16)
        .frame(width: 350, height: 200)
        .background(Color.black.opacity(0.8))
    }
}

@MainActor
class LLMManagementViewModel: ObservableObject {
    @Published var models: [OllamaModel] = []
    @Published var isLoading = false
    @Published var isConnected = false
    @Published var defaultModel = ""
    @Published var systemPrompt = ""
    @Published var alertMessage = ""
    @Published var alertTitle = ""
    @Published var downloadingModel = ""
    @Published var downloadProgress = ""
    @Published var needsServerRestart = false
    
    private let ollamaClient = OllamaClient()
    private let config = SharedConfiguration.load()
    
    init() {
        defaultModel = config.defaultModel
        systemPrompt = config.systemPrompt
    }
    
    func refreshModels() async {
        isLoading = true
        
        do {
            models = try await ollamaClient.listModels()
            isConnected = true
        } catch {
            isConnected = false
            showAlert("Connection Error", "Failed to connect to Ollama: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func downloadModel(_ name: String) async {
        downloadingModel = name
        downloadProgress = "Starting download..."
        
        do {
            try await ollamaClient.pullModel(name: name) { progress in
                Task { @MainActor in
                    self.downloadProgress = progress
                }
            }
            await refreshModels()
            showAlert("Success", "Model '\(name)' downloaded successfully!")
        } catch {
            showAlert("Download Error", "Failed to download model '\(name)': \(error.localizedDescription)")
        }
        
        downloadingModel = ""
        downloadProgress = ""
    }
    
    func removeModel(_ name: String) async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/ollama")
        process.arguments = ["rm", name]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                await refreshModels()
                showAlert("Success", "Model '\(name)' removed successfully!")
            } else {
                showAlert("Removal Error", "Failed to remove model '\(name)'. Exit code: \(process.terminationStatus)")
            }
        } catch {
            showAlert("Removal Error", "Failed to remove model '\(name)': \(error.localizedDescription)")
        }
    }
    
    func setDefaultModel(_ name: String) {
        defaultModel = name
        
        // Update configuration file
        do {
            let updatedConfig = config
            // Create a new configuration with the updated default model
            let newConfig = SharedConfiguration(
                listenAddress: updatedConfig.listenAddress,
                telnetPort: updatedConfig.telnetPort,
                controlHost: updatedConfig.controlHost,
                controlPort: updatedConfig.controlPort,
                width: updatedConfig.width,
                wrap: updatedConfig.wrap,
                maxInputLength: updatedConfig.maxInputLength,
                enableRateLimiting: updatedConfig.enableRateLimiting,
                rateLimitRequests: updatedConfig.rateLimitRequests,
                rateLimitWindow: updatedConfig.rateLimitWindow,
                defaultModel: name,
                ollamaBaseURL: updatedConfig.ollamaBaseURL,
                requestTimeout: updatedConfig.requestTimeout,
                resourceTimeout: updatedConfig.resourceTimeout,
                systemPrompt: updatedConfig.systemPrompt,
                logLevel: updatedConfig.logLevel,
                enableAuditLogging: updatedConfig.enableAuditLogging
            )
            
            try newConfig.save(to: Constants.configPath)
            needsServerRestart = true
            showAlert("Success", "Default model set to '\(name)'. Configuration saved. Use the 'Restart Server' button to apply changes.")
        } catch {
            showAlert("Configuration Error", "Failed to save configuration: \(error.localizedDescription)")
        }
    }
    
    func updateSystemPrompt(_ newPrompt: String) {
        systemPrompt = newPrompt
        
        // Update configuration file
        do {
            let updatedConfig = config
            // Create a new configuration with the updated system prompt
            let newConfig = SharedConfiguration(
                listenAddress: updatedConfig.listenAddress,
                telnetPort: updatedConfig.telnetPort,
                controlHost: updatedConfig.controlHost,
                controlPort: updatedConfig.controlPort,
                width: updatedConfig.width,
                wrap: updatedConfig.wrap,
                maxInputLength: updatedConfig.maxInputLength,
                enableRateLimiting: updatedConfig.enableRateLimiting,
                rateLimitRequests: updatedConfig.rateLimitRequests,
                rateLimitWindow: updatedConfig.rateLimitWindow,
                defaultModel: updatedConfig.defaultModel,
                ollamaBaseURL: updatedConfig.ollamaBaseURL,
                requestTimeout: updatedConfig.requestTimeout,
                resourceTimeout: updatedConfig.resourceTimeout,
                systemPrompt: newPrompt,
                logLevel: updatedConfig.logLevel,
                enableAuditLogging: updatedConfig.enableAuditLogging
            )
            
            try newConfig.save(to: Constants.configPath)
            needsServerRestart = true
            showAlert("Success", "System prompt updated successfully. Use the 'Restart Server' button to apply changes.")
        } catch {
            showAlert("Configuration Error", "Failed to save configuration: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
    }
    
    func clearAlert() {
        alertMessage = ""
        alertTitle = ""
    }
}


