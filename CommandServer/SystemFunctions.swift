// 2025-02-02, Swift 5, macOS 15.1, Xcode 16.0
// Copyright © 2025 amaider. (github.com/amaider)

/// Singing & Capabilities -> Hardened Runtime -> Resource Access -> Apple Events
/// Info.plist: Privacy - AppleEvents Sending Usage Description
/// Entitlements: com.apple.security.temporary-exception.apple-events: Array -> [Item0: String = "com.apple.systemevents"]

import Foundation

func macOSSleep() {
    let script: String = """
        tell application "System Events" to sleep
        """
    
//    let script: String = "pmset displaysleepnow"
    
//    let script: String = """
//      set theDialogText to "The curent date and time is " & (current date) & "."
//      display dialog theDialogText
//      """
    
    DispatchQueue.global(qos: .background).async {
        let appleScript: NSAppleScript? = NSAppleScript(source: script)
        var errorDict: NSDictionary? = nil
        
        let possibleResult = appleScript?.executeAndReturnError(&errorDict)
        if errorDict != nil {
            NSLog("[CommandServer]: error: \(String(describing: errorDict)), result:\(String(describing: possibleResult))")
        }
    }
}
