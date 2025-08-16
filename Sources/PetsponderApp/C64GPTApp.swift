import SwiftUI

@main
struct C64GPTApp: App {
    var body: some Scene {
        WindowGroup {
            UnifiedManagementView()
        }
        .defaultSize(width: 600, height: 700)
    }
}
