// 2025-02-02, Swift 5, macOS 15.1, Xcode 16.0
// Copyright © 2025 amaider. (github.com/amaider)

import SwiftUI
import ServiceManagement

@main
struct CommandServerApp: App {
    let server: HTTPServer = HTTPServer()
    
    var body: some Scene {
        MenuBarExtra(content: {
            Text("Listener: \(server.listenerState)")
            Text("Connection: \(server.connectionState)")
            
            Button("Restart Server", action: {
                server.stop()
                server.start()
            })
            
            Menu("History (\(self.server.connectionsHistory.count))", content: {
                Button("Clear", action: { self.server.connectionsHistory = [] })
                ForEach(self.server.connectionsHistory, id: \.self, content: {
                    Divider()
                    Text($0).font(.system(size: 10))
                })
            })
            
            Divider()
            
            Button("Quit", action: {
                self.server.stop()
                NSApplication.shared.terminate(nil)
            })
        }, label: {
            MenuBarExtraLabel(server: self.server)
//                .onReceive(self.wakeUpPublisher, perform: { _ in
//
//                })
        })
    }
}
