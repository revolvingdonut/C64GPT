import SwiftUI

@main
struct C64GPTApp: App {
    var body: some Scene {
        WindowGroup {
            UnifiedManagementView()
        }
        .defaultSize(width: 800, height: 900)
    }
}
