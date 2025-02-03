// 2025-02-02, Swift 5, macOS 15.1, Xcode 16.0
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
                guard let data else {
                    self.sendResponse(code: 400, reasonPhrase: "Bad Request", body: "Error: No Data", to: connection)
                    return
                }
                
                guard let request: String = String(data: data, encoding: .utf8) else {
                    self.sendResponse(code: 400, reasonPhrase: "Bad Request", body: "Error: Data -> String", to: connection)
                    return
                }
                
                self.connectionsHistory.append("\(Date.now): \(request)")
                
                /// parse paths
                if request.contains("GET /sleep") {
                    self.sendResponse(code: 200, reasonPhrase: "OK", body: "", to: connection)
                    macOSSleep()
                } else {
                    self.sendResponse(code: 404, reasonPhrase: "Not Found", body: "Path not implemented", to: connection)
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
    
    func sendResponse(code: Int, reasonPhrase: String, body: String, to connection: NWConnection) {
        let response: String = "HTTP/1.1 \(code) \(reasonPhrase)\r\nContent-Type: plain/text\r\n\r\n\(body)\r\n"
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ error in
            if let error {
                print("Error sending: \(error)")
            }
            connection.cancel()
        }))
    }
}
