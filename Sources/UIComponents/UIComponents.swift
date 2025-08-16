import SwiftUI
import Core

// MARK: - Status Indicator
public struct StatusIndicator: View {
    public let isActive: Bool
    public let activeText: String
    public let inactiveText: String
    public let activeColor: Color
    public let inactiveColor: Color
    public let size: CGFloat
    
    public init(
        isActive: Bool,
        activeText: String = "Online",
        inactiveText: String = "Offline",
        activeColor: Color = .green,
        inactiveColor: Color = .red,
        size: CGFloat = 8
    ) {
        self.isActive = isActive
        self.activeText = activeText
        self.inactiveText = inactiveText
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.size = size
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: size, height: size)
                .shadow(
                    color: isActive ? activeColor.opacity(0.3) : inactiveColor.opacity(0.3),
                    radius: 2
                )
            
            Text(isActive ? activeText : inactiveText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isActive ? activeColor : inactiveColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? activeColor.opacity(0.1) : inactiveColor.opacity(0.1))
        )
    }
}

// MARK: - Action Button
public struct ActionButton: View {
    public let title: String
    public let icon: String
    public let action: () -> Void
    public let isEnabled: Bool
    public let backgroundColor: Color
    public let foregroundColor: Color
    public let isLoading: Bool
    
    public init(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        backgroundColor: Color = .gray,
        foregroundColor: Color = .white,
        isLoading: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isEnabled = isEnabled
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.isLoading = isLoading
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .foregroundColor(foregroundColor)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .foregroundColor(foregroundColor)
        }
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Compact Action Button
public struct CompactActionButton: View {
    public let title: String
    public let icon: String
    public let action: () -> Void
    public let isEnabled: Bool
    public let backgroundColor: Color
    public let foregroundColor: Color
    public let isLoading: Bool
    
    public init(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        backgroundColor: Color = .gray,
        foregroundColor: Color = .white,
        isLoading: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isEnabled = isEnabled
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.isLoading = isLoading
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .foregroundColor(foregroundColor)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
            )
            .foregroundColor(foregroundColor)
        }
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Tab Button
public struct TabButton: View {
    public let title: String
    public let isSelected: Bool
    public let action: () -> Void
    
    public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.gray : Color.gray.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.gray : Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Info Card
public struct InfoCard: View {
    public let title: String
    public let subtitle: String
    public let icon: String
    public let backgroundColor: Color
    
    public init(
        title: String,
        subtitle: String,
        icon: String,
        backgroundColor: Color = Color.gray.opacity(0.12)
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.darkGray))
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Connection Info
public struct ConnectionInfo: View {
    public let port: Int
    public let command: String
    
    public init(port: Int = 6400, command: String = Constants.telnetCommand) {
        self.port = port
        self.command = command
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Telnet Port", systemImage: "network")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.darkGray))
                
                Spacer()
                
                Text("\(port)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray)
                    )
            }
            
            HStack {
                Label("Connection", systemImage: "terminal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.darkGray))
                
                Spacer()
                
                Text(command)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(.darkGray))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
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

// MARK: - Alert Banner
public struct AlertBanner: View {
    public let title: String
    public let message: String
    public let type: AlertType
    public let actionTitle: String?
    public let action: (() -> Void)?
    
    public enum AlertType {
        case info, warning, error, success
        
        public var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .success: return .green
            }
        }
        
        public var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }
    
    public init(
        title: String,
        message: String,
        type: AlertType = .info,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.type = type
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.icon)
                .font(.system(size: 14))
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(type.color)
                    )
            }
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
        .padding(.horizontal, 12)
    }
}

// MARK: - Loading View
public struct LoadingView: View {
    public let message: String
    
    public init(message: String = "Loading...") {
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            ProgressView()
                .scaleEffect(1.0)
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 30)
    }
}

// MARK: - Empty State View
public struct EmptyStateView: View {
    public let icon: String
    public let title: String
    public let message: String
    public let actionTitle: String?
    public let action: (() -> Void)?
    
    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 30)
    }
}

// MARK: - Compact Button
public struct CompactButton: View {
    public let title: String
    public let icon: String
    public let action: () -> Void
    public let isEnabled: Bool
    public let isPrimary: Bool
    public let isWarning: Bool
    
    public init(
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
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .medium))
                Text(title)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(.white.opacity(isEnabled ? 0.9 : 0.5))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 3)
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
