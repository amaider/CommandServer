// 2025-02-02, Swift 6.0, macOS 15.1, Xcode 16.0
// Copyright © 2025 amaider. (github.com/amaider)

import Foundation
import Network

@Observable class HTTPServer {
    var listenerState: String = "nil"
    var connectionStatus: NWConnection.State?
    var connectionState: String {
        switch self.connectionStatus {
            case .setup: "setup"
            case .waiting(let nWError): "waiting(\(nWError))"
            case .preparing: "preparing"
            case .ready: "ready"
            case .failed(let nWError): "failed(\(nWError))"
            case .cancelled: "cancelled"
            case .none: "none"
            case .some(let str): "some(\(str))"
        }
    }
    var connectionsHistory: [String] = []
    
    @ObservationIgnored private var listener: NWListener!
    
    init() {
        self.start()
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
            switch state {
                case .setup: self.listenerState = "setup"
                case .waiting(let nWError): self.listenerState = "waiting(\(nWError))"
                case .ready: self.listenerState = "ready"
                case .failed(let nWError): self.listenerState = "failed(\(nWError))"
                case .cancelled: self.listenerState = "cancelled"
                @unknown default: self.listenerState = "default"
            }
        }
        
        /// handle connection
        listener.newConnectionHandler = { connection in
            connection.start(queue: .main)
            
            connection.receive(minimumIncompleteLength: 1, maximumLength: 512, completion: { data, context, isComplete, error in
                var sendToSleep: Bool = false
                
                guard let data else {
                    self.sendResponse(response: "HTTP/1.1 400 Bad Request\r\nContent-Type: plain/text\r\n\r\nError: No Data\r\n", to: connection)
                    return
                }
                
                guard let request: String = String(data: data, encoding: .utf8) else {
                    self.sendResponse(response: "HTTP/1.1 400 Bad Request\r\nContent-Type: plain/text\r\n\r\nError: Data -> String\r\n", to: connection)
                    return
                }
                
                self.connectionsHistory.append("\(Date.now): \(request)")
                
                /// parse subdomain
                if request.contains("GET /sleep") {
                    self.sendResponse(response: "HTTP/1.1 200 OK\r\n\r\n", to: connection)
                    sendToSleep = true
                } else {
                    self.sendResponse(response: "HTTP/1.1 404 Not Found\r\nContent-Type: plain/text\r\n\r\n Subdomain not implemented\r\n", to: connection)
                }
                
                /// send to sleep after response?
                if sendToSleep {
                    macOSSleep()
                }
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
    
    func sendResponse(response: String, to connection: NWConnection) {
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ error in
            if let error {
                print("Error sending: \(error)")
            }
            connection.cancel()
        }))
    }
}
