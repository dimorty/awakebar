import SwiftUI

@main
struct AwakeBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let jiggler = MouseJiggler()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController(jiggler: jiggler)
        
        NSApp.setActivationPolicy(.accessory)
    }
}
