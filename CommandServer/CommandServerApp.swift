// 2025-02-02, Swift 5, macOS 15.1, Xcode 16.0
// Copyright © 2025 amaider. (github.com/amaider)

import SwiftUI
import ServiceManagement

@main
struct CommandServerApp: App {
    // let server: HTTPServer = HTTPServer()
    let server: HTTPServer = HTTPServer(routes: [
        "sleep": {
            macOSSleep()
            return nil
        },
        "alive": { return "alive" },
    ])
    
    let ipv4: String? = getIPv4Address()
    
    var body: some Scene {
        MenuBarExtra(content: {
            Text("http://\(ipv4 ?? "nil"):8080")
            Text("Listener: \(server.listenerState?.string ?? "nil")")
                .foregroundStyle(server.listenerState == .ready ? .green : .primary)
            Text("Connection: \(server.connectionStatus?.string ?? "nil")")
            
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
