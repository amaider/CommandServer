// 2025-02-02, Swift 5, macOS 15.1, Xcode 16.0
// Copyright © 2025 amaider. (github.com/amaider)

import Foundation
import Network

@Observable class HTTPServer {
    var listenerState: NWListener.State?
    var connectionStatus: NWConnection.State?
    var connectionsHistory: [String] = []
    
    @ObservationIgnored private var listener: NWListener!
    
    @ObservationIgnored let routes: [String: () -> String?]
    
    init(routes: [String: () -> String?]) {
        self.routes = routes
        
        self.start()
    }
    
    deinit {
        self.stop()
    }
    
    func start() {
        let parameters: NWParameters = .tcp
        parameters.allowLocalEndpointReuse = true
        
        do {
            self.listener = try NWListener(using: parameters, on: 8080)
        } catch {
            print("Error starting listener: \(error)")
            return
        }
        listener.stateUpdateHandler = { state in
            self.listenerState = state
        }
        
        /// handle connection
        listener.newConnectionHandler = { connection in
            connection.start(queue: .main)
            
            connection.receive(minimumIncompleteLength: 1, maximumLength: 512, completion: { data, context, isComplete, error in
                guard let data else {
                    self.sendResponse(code: 400, reasonPhrase: "Bad Request", body: "Error: No Data", to: connection)
                    return
                }
                
                guard let request: String = String(data: data, encoding: .utf8) else {
                    self.sendResponse(code: 400, reasonPhrase: "Bad Request", body: "Error: Data -> String", to: connection)
                    return
                }
                
                self.connectionsHistory.append("\(Date.now): \(request)")
                
                guard let requestLine: String = request.components(separatedBy: "\r\n").first else {
                    self.sendResponse(code: 500, reasonPhrase: "Internal Server Error", body: "Failed to get the first line of the request", to: connection)
                    return
                }
                
                let requestLineParts = requestLine.split(separator: " ")
                guard requestLineParts.count >= 2 else {
                    self.sendResponse(code: 500, reasonPhrase: "Internal Server Error", body: "Failed to split first request line into methond and path", to: connection)
                    return
                }
                
                // let method: String = String(requestLineParts[0])
                let path: String = String(requestLineParts[1].dropFirst())
                
                guard let closure: () -> String? = self.routes[path] else {
                    self.sendResponse(code: 404, reasonPhrase: "Not Found", body: "Path not implemented", to: connection)
                    return
                }
                
                let body: String? = closure()
                self.sendResponse(code: 200, reasonPhrase: "OK", body: "\(body ?? "")", to: connection)
            })
            
            connection.stateUpdateHandler = { state in
                self.connectionStatus = state
            }
        }
        
        /// start the listener
        listener.start(queue: .main)
    }
    
    func stop() {
        listener.cancel()
    }
    
    func sendResponse(code: Int, reasonPhrase: String, body: String, to connection: NWConnection) {
        let response: String = "HTTP/1.1 \(code) \(reasonPhrase)\r\nContent-Type: text/plain\r\nContent-Length: \(body.count)\r\n\r\n\(body)"
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ error in
            if let error {
                print("Error sending: \(error)")
            }
            connection.cancel()
        }))
    }
}


func getIPv4Address() -> String? {
    var address: String?
    
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else {
        return nil
    }
    
    defer {
        freeifaddrs(ifaddr)
    }
    
    var ptr = ifaddr
    while ptr != nil {
        defer {
            ptr = ptr?.pointee.ifa_next
        }
        
        let interface = ptr!.pointee
        let addrFamily = interface.ifa_addr.pointee.sa_family
        
        // IPv4 only.
        guard addrFamily == UInt8(AF_INET) else {
            continue
        }
        
        let name = String(cString: interface.ifa_name)
        
        // Wi-Fi on iOS, Ethernet on macOS.
        if name != "lo0" {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            
            getnameinfo(
                interface.ifa_addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            
            address = String(cString: hostname)
            break
        }
    }
    
    return address
}
