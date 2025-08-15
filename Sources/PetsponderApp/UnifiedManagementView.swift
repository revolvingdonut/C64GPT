import SwiftUI
import OllamaClient
import TelnetGateway

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
                // Modern Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("C64GPT Management")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(selectedTab == 0 ? "Server Management" : "LLM Model Management")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // Overall Status Badge
                        HStack(spacing: 8) {
                            Circle()
                                .fill(serverManager.isRunning && llmViewModel.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                                .shadow(color: serverManager.isRunning && llmViewModel.isConnected ? .green.opacity(0.3) : .red.opacity(0.3), radius: 4)
                            
                            Text(serverManager.isRunning && llmViewModel.isConnected ? "Ready" : "Not Ready")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(serverManager.isRunning && llmViewModel.isConnected ? .green : .red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.15))
                        )
                    }
                    
                    // Tab Bar
                    HStack(spacing: 8) {
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
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
        .frame(minWidth: 700, minHeight: 800)
        .onAppear {
            Task {
                await llmViewModel.refreshModels()
            }
        }
        .sheet(isPresented: $showingModelDownload) {
            ModernModelDownloadView(
                isPresented: $showingModelDownload,
                onDownload: { modelName in
                    Task {
                        await llmViewModel.downloadModel(modelName)
                    }
                }
            )
        }
        .sheet(isPresented: $showingSystemPromptEditor) {
            SystemPromptEditorView(
                isPresented: $showingSystemPromptEditor,
                currentPrompt: llmViewModel.systemPrompt,
                onSave: { newPrompt in
                    llmViewModel.updateSystemPrompt(newPrompt)
                }
            )
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

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
                                    Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.gray : Color.gray.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.gray : Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ServerManagementTab: View {
    @ObservedObject var serverManager: ServerManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Server Status Card
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server Status")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(.darkGray))
                        
                        Text(serverManager.isRunning ? "Running" : "Stopped")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(serverManager.isRunning ? .green : .red)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(serverManager.isRunning ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                            .shadow(color: serverManager.isRunning ? .green.opacity(0.3) : .red.opacity(0.3), radius: 4)
                        
                        Text(serverManager.isRunning ? "Online" : "Offline")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(serverManager.isRunning ? .green : .red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(serverManager.isRunning ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                }
                
                // Connection Info
                if serverManager.isRunning {
                    VStack(spacing: 12) {
                        HStack {
                            Label("Telnet Port", systemImage: "network")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(.darkGray))
                            
                            Spacer()
                            
                            Text("6400")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray)
                                )
                        }
                        
                        HStack {
                            Label("Connection", systemImage: "terminal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(.darkGray))
                            
                            Spacer()
                            
                            Text("telnet localhost 6400")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(.darkGray))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.15))
                                )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 24)
            
            // Control Buttons
            VStack(spacing: 12) {
                Button(action: {
                    if serverManager.isRunning {
                        serverManager.stopServer()
                    } else {
                        serverManager.startServer()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: serverManager.isRunning ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text(serverManager.isRunning ? "Stop Server" : "Start Server")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(serverManager.isRunning ? Color.gray : Color.gray)
                    )
                    .foregroundColor(.white)
                }
                .disabled(serverManager.isStarting)
                
                Button(action: {
                    // Copy connection command to clipboard
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("telnet localhost 6400", forType: .string)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                        Text("Copy Connection Command")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray)
                    )
                    .foregroundColor(.white)
                }
                .disabled(!serverManager.isRunning)
            }
            .padding(.horizontal, 24)
            
            // Status Messages
            if !serverManager.statusMessage.isEmpty {
                HStack {
                    Image(systemName: serverManager.isRunning ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(serverManager.isRunning ? .green : .orange)
                    
                    Text(serverManager.statusMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(serverManager.isRunning ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                )
                .padding(.horizontal, 24)
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
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await viewModel.refreshModels()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Refresh")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                    )
                }
                .disabled(viewModel.isLoading)
                
                Button(action: {
                    showingModelDownload = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Download Model")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray)
                    )
                }
                .disabled(!viewModel.isConnected || !viewModel.downloadingModel.isEmpty)
                
                Button(action: {
                    showingSystemPromptEditor = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 14, weight: .medium))
                        Text("System Prompt")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                    )
                }
                
                Button(action: {
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
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.system(size: 14, weight: .medium))
                        Text("Restart Server")
                            .font(.system(size: 14, weight: .medium))
                        if viewModel.needsServerRestart {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.needsServerRestart ? Color.red : Color.orange)
                    )
                }
                .disabled(serverManager.isStarting)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Download Progress
            if !viewModel.downloadingModel.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Downloading \(viewModel.downloadingModel)...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    if !viewModel.downloadProgress.isEmpty {
                        Text(viewModel.downloadProgress)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            
            // Restart Required Notification
            if viewModel.needsServerRestart {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server Restart Required")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Configuration changes have been made. Restart the server to apply them.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Restart Now") {
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange)
                    )
                    .disabled(serverManager.isStarting)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            
            // Models Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Installed Models")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if !viewModel.defaultModel.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                                                    Text("Default: \(viewModel.defaultModel)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading models...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
                } else if viewModel.models.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No models installed")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Download a model to get started with AI conversations")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            showingModelDownload = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Download Your First Model")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray)
                            )
                        }
                        .disabled(!viewModel.isConnected)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.models, id: \.name) { model in
                                ModernModelRowView(
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
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// Reuse existing components
struct ModernModelRowView: View {
    let model: OllamaModel
    let isDefault: Bool
    let onSetDefault: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Model Icon
            VStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundColor(isDefault ? .blue : .secondary)
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(isDefault ? Color.blue.opacity(0.1) : Color.gray.opacity(0.2))
            )
            
            // Model Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if isDefault {
                        Text("DEFAULT")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue)
                            )
                            .foregroundColor(.white)
                    }
                }
                
                HStack(spacing: 12) {
                    Label(formatFileSize(model.size), systemImage: "externaldrive")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Label(formatDate(model.modifiedAt), systemImage: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                if !isDefault {
                    Button(action: onSetDefault) {
                        HStack(spacing: 4) {
                            Image(systemName: "star")
                                .font(.system(size: 12))
                            Text("Set Default")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
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

struct ModernModelDownloadView: View {
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
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Download Model")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Choose a model to download from Ollama")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Popular Models
            VStack(alignment: .leading, spacing: 16) {
                Text("Popular Models")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(popularModels, id: \.self) { model in
                        Button(action: {
                            modelName = model
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 14))
                                    .foregroundColor(modelName == model ? .white : .blue)
                                
                                Text(model)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(modelName == model ? .white : .white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(modelName == model ? Color.blue : Color.gray.opacity(0.2))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Custom Model Input
            VStack(alignment: .leading, spacing: 12) {
                Text("Or enter custom model name:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("e.g., llama3.2:8b", text: $modelName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 14))
            }
            
            // Action Buttons
            HStack(spacing: 16) {
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
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(modelName.isEmpty ? Color.gray : Color.blue)
                )
            }
        }
        .padding(32)
        .frame(width: 500, height: 400)
        .background(Color.gray.opacity(0.1))
    }
}

struct SystemPromptEditorView: View {
    @Binding var isPresented: Bool
    let currentPrompt: String
    let onSave: (String) -> Void
    
    @State private var editedPrompt: String = ""
    @State private var showingResetAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("System Prompt Editor")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Customize how the AI assistant behaves")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Editor
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("System Prompt")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Reset to Default") {
                        showingResetAlert = true
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
                }
                
                TextEditor(text: $editedPrompt)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
                    .frame(minHeight: 200)
            }
            
            // Help Text
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Keep it concise and clear")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    Text("• Define the AI's personality and behavior")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    Text("• Avoid markdown or special formatting")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 4)
            
            // Action Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                .foregroundColor(.white.opacity(0.7))
                
                Button("Save Changes") {
                    onSave(editedPrompt)
                    isPresented = false
                }
                .keyboardShortcut(.return)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )
            }
        }
        .padding(32)
        .frame(width: 600, height: 500)
        .background(Color.gray.opacity(0.1))
        .onAppear {
            editedPrompt = currentPrompt
        }
        .alert("Reset to Default", isPresented: $showingResetAlert) {
            Button("Reset") {
                editedPrompt = "You are a helpful AI assistant. Keep replies concise, friendly, and natural. Respond in plain text without special formatting or markdown."
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset the system prompt to the default value. Are you sure?")
        }
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
    private let config = Configuration.load()
    
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
            let newConfig = Configuration(
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
            
            try newConfig.save(to: "Config/config.json")
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
            let newConfig = Configuration(
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
            
            try newConfig.save(to: "Config/config.json")
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

class ServerManager: ObservableObject {
    @Published var isRunning = false
    @Published var isStarting = false
    @Published var statusMessage = ""
    
    private var serverProcess: Process?
    private var serverPID: Int32?
    private var statusCheckTimer: Timer?
    
    func startServer() {
        isStarting = true
        statusMessage = "Starting server..."
        
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
            DispatchQueue.main.async {
                self?.handleServerTermination(process)
            }
        }
        
        do {
            try process.run()
            self.serverProcess = process
            self.serverPID = process.processIdentifier
            
            // Check if process started successfully
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if process.isRunning {
                    self.isRunning = true
                    self.isStarting = false
                    self.statusMessage = "Server started successfully!"
                    self.startStatusChecking()
                    
                    // Clear status message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if self.statusMessage == "Server started successfully!" {
                            self.statusMessage = ""
                        }
                    }
                } else {
                    self.isStarting = false
                    self.statusMessage = "Failed to start server"
                    self.serverProcess = nil
                    self.serverPID = nil
                }
            }
        } catch {
            isStarting = false
            statusMessage = "Error starting server: \(error.localizedDescription)"
            serverProcess = nil
            serverPID = nil
        }
    }
    
    func stopServer() {
        statusMessage = "Stopping server..."
        
        // First try to stop the managed process
        if let process = serverProcess, process.isRunning {
            process.terminate()
            
            // Give it a moment to terminate gracefully
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !process.isRunning {
                    self.handleServerStopped()
                } else {
                    // Force kill if it didn't terminate gracefully
                    process.interrupt()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        DispatchQueue.main.async {
            self.isRunning = false
            self.isStarting = false
            self.serverProcess = nil
            self.serverPID = nil
            self.stopStatusChecking()
            
            if process.terminationStatus == 0 {
                self.statusMessage = "Server stopped gracefully."
            } else {
                self.statusMessage = "Server stopped with exit code: \(process.terminationStatus)"
            }
            
            // Clear status message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.statusMessage.contains("Server stopped") {
                    self.statusMessage = ""
                }
            }
        }
    }
    
    private func handleServerStopped() {
        DispatchQueue.main.async {
            self.isRunning = false
            self.isStarting = false
            self.serverProcess = nil
            self.serverPID = nil
            self.stopStatusChecking()
            self.statusMessage = "Server stopped."
            
            // Clear status message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.statusMessage == "Server stopped." {
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
        let pidFile = FileManager.default.currentDirectoryPath + "/c64gpt_unified.pid"
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
            self?.checkServerStatus()
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
        stopStatusChecking()
        if let process = serverProcess, process.isRunning {
            process.terminate()
        }
    }
}
