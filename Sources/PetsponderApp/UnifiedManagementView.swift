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
                        StatusIndicator(
                            isActive: serverManager.isRunning && llmViewModel.isConnected,
                            activeText: "Ready",
                            inactiveText: "Not Ready",
                            size: 8
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
            .presentationDetents([.large])
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
                    StatusIndicator(
                        isActive: serverManager.isRunning,
                        activeText: "Online",
                        inactiveText: "Offline",
                        size: 12
                    )
                }
                
                // Connection Info
                if serverManager.isRunning {
                    ConnectionInfo()
                }
            }
            .padding(.horizontal, 24)
            
            // Control Buttons
            VStack(spacing: 12) {
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
                    isLoading: serverManager.isStarting
                )
                
                ActionButton(
                    title: "Copy Connection Command",
                    icon: "doc.on.doc",
                    action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(Constants.telnetCommand, forType: .string)
                    },
                    isEnabled: serverManager.isRunning
                )
            }
            .padding(.horizontal, 24)
            
            // Status Messages
            if !serverManager.statusMessage.isEmpty {
                AlertBanner(
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
                    // Test inline editing
                    print("Inline test button pressed")
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                        Text("Test Input")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.2))
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
            
            // Test Input Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Test Input (Inline)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                
                TextField("Test typing here...", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, 8)
            
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
    
    @State private var editedPrompt: String
    
    init(isPresented: Binding<Bool>, currentPrompt: String, onSave: @escaping (String) -> Void) {
        self._isPresented = isPresented
        self.currentPrompt = currentPrompt
        self.onSave = onSave
        self._editedPrompt = State(initialValue: currentPrompt)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Simple header
            Text("System Prompt")
                .font(.headline)
                .foregroundColor(.white)
            
            // Simple text editor
            TextEditor(text: $editedPrompt)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .background(Color.black.opacity(0.3))
                .frame(height: 150)
            
            // Simple buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Button("Reset") {
                    editedPrompt = "You are a helpful AI assistant. Keep replies concise, friendly, and natural. Respond in plain text without special formatting or markdown."
                }
                
                Button("Save") {
                    onSave(editedPrompt)
                    isPresented = false
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400, height: 250)
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


