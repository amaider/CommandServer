// 2025-02-02, Swift 6.0, macOS 15.1, Xcode 16.0
// Copyright © 2025 amaider. (github.com/amaider)

import SwiftUI

struct MenuBarExtraLabel: View {
    let server: HTTPServer
    
    private var symbolConfiguration: NSImage.SymbolConfiguration {
        switch self.server.connectionStatus {
            case .setup:
                NSImage.SymbolConfiguration(hierarchicalColor: .yellow)
            case .waiting(_):
                NSImage.SymbolConfiguration(hierarchicalColor: .red)
            case .preparing:
                NSImage.SymbolConfiguration(hierarchicalColor: .yellow)
            case .ready:
                NSImage.SymbolConfiguration(hierarchicalColor: .gray)
            case .failed(_):
                NSImage.SymbolConfiguration(hierarchicalColor: .red)
            case .cancelled:
                NSImage.SymbolConfiguration(hierarchicalColor: .gray)
            case .none:
                NSImage.SymbolConfiguration(hierarchicalColor: .gray)
            @unknown default:
                NSImage.SymbolConfiguration(hierarchicalColor: .magenta)
        }
    }
    
    var body: some View {
        if let nsImage: NSImage = NSImage(systemSymbolName: "server.rack", accessibilityDescription: nil)?.withSymbolConfiguration(self.symbolConfiguration) {
            Image(nsImage: nsImage)
        } else {
            Image(systemName: "exclamationmark.questionmark")
        }
    }
}
