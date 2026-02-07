import Foundation
import CoreGraphics
import AppKit
import Combine

final class MouseJiggler: ObservableObject {
    @Published private(set) var isRunning = false
    
    private var timer: Timer?
    private var toggle = false
    
    var interval: TimeInterval = 5
    var delta: CGFloat = 1
    
    func start() {
        guard !isRunning else { return }
        
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        guard trusted else {
            let alert = NSAlert()
            alert.messageText = "Accessibility permission required"
            alert.informativeText = "Enable Accessibility for this app:\nSystem Settings → Privacy & Security → Accessibility."
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            
            NSApp.activate(ignoringOtherApps: true)
            
            let resp = alert.runModal()
            if resp == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            return
        }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
            [weak self] _ in self?.jiggle()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func jiggle() {
        guard let event = CGEvent(source: nil) else { return }
        let location = event.location
        
        let dx: CGFloat = toggle ? delta : -delta
        toggle.toggle()
        
        let newPoint = CGPoint(x: location.x + dx, y: location.y)
        
        if let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: newPoint, mouseButton: .left) {
            move.post(tap: .cghidEventTap)
        }
    }
}
