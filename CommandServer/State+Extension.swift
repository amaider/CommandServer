// 2026-07-24, Swift 6.0, macOS 15.3, Xcode 16.0
// Copyright © 2026 amaider. All rights reserved.

import Network

extension NWListener.State {
    var string: String {
        switch self {
            case .setup: "setup"
            case .waiting(let nWError): "waiting: \(nWError)"
            case .ready: "ready"
            case .failed(let nWError): "failed: \(nWError)"
            case .cancelled: "cancelled"
            @unknown default: "@unknown"
        }
    }
}

extension NWConnection.State {
    var string: String {
        switch self {
            case .setup: "setup"
            case .waiting(let nWError): "waiting: \(nWError)"
            case .preparing: "preparing"
            case .ready: "ready"
            case .failed(let nWError): "failed: \(nWError)"
            case .cancelled: "cancelled"
            @unknown default: "@unknown"
        }
    }
}
