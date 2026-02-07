import AppKit
import SwiftUI
import Combine

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let menu: NSMenu
    private let jiggler: MouseJiggler
    private var cancellables = Set<AnyCancellable>()
    
    private let startStopItem = NSMenuItem(title: "Start", action: #selector(toggleStartStop), keyEquivalent: "s")
    private let intervalItem = NSMenuItem(title: "Interval: 30s", action: nil, keyEquivalent: "")
    private let deltaItem = NSMenuItem(title: "Delta: 1px", action: nil, keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Start at login", action: #selector(toggleStartAtLogin), keyEquivalent: "")
    
    init(jiggler: MouseJiggler) {
        self.jiggler = jiggler
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.menu = NSMenu()
        super.init()
        
        jiggler.$isRunning
            .removeDuplicates()
            .sink { [weak self] running in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.startStopItem.title = running ? "Stop" : "Start"
                    self.updateStatusIcon()
                }
            }
            .store(in: &cancellables)
        
        updateStatusIcon()
        
        startStopItem.target = self
        loginItem.target = self
        
        let intervalSubmenu = makeIntervalSubmenu()
        let intervalRoot = NSMenuItem(title: "Interval", action: nil, keyEquivalent: "")
        intervalRoot.submenu = intervalSubmenu
        
        let deltaSubmenu = makeDeltaSubmenu()
        let deltaRoot = NSMenuItem(title: "Delta", action: nil, keyEquivalent: "")
        deltaRoot.submenu = deltaSubmenu
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        
        menu.addItem(startStopItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(intervalItem)
        menu.addItem(intervalRoot)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(deltaItem)
        menu.addItem(deltaRoot)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
        
        refreshLabels()
    }
    
    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }

        let symbolName = "cursorarrow.square.fill"
        let baseConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)

        let image: NSImage?

        if jiggler.isRunning {
            let coloredConfig = baseConfig.applying(
                NSImage.SymbolConfiguration(paletteColors: [.systemGreen, .white])
            )

            image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Jiggler")?
                .withSymbolConfiguration(coloredConfig)

            button.image = image
            button.image?.isTemplate = false
        } else {
            image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Jiggler")?
                .withSymbolConfiguration(baseConfig)

            button.image = image
            button.image?.isTemplate = true
        }
    }
    
    private func makeIntervalSubmenu() -> NSMenu {
        let sub = NSMenu()
        
        [5, 10, 15, 30, 60, 120, 300].forEach { sec in
            let item = NSMenuItem(title: "\(sec)s", action: #selector(setInterval(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = sec
            sub.addItem(item)
        }
        
        return sub
    }
    
    private func makeDeltaSubmenu() -> NSMenu {
        let sub = NSMenu()
        
        [1, 2, 3, 5, 8, 10].forEach { px in
            let item = NSMenuItem(title: "\(px)px", action: #selector(setDelta(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = px
            sub.addItem(item)
        }
        
        return sub
    }
    
    private func refreshLabels() {
        startStopItem.title = jiggler.isRunning ? "Stop" : "Start"
        intervalItem.title = "Interval: \(Int(jiggler.interval))s"
        deltaItem.title = "Delta: \(Int(jiggler.delta))px"
        loginItem.state = LoginItemManager.isEnabled() ? .on : .off
    }
    
    private func restartJigglerIfRunning() {
        guard jiggler.isRunning else { return }
        jiggler.stop()
        DispatchQueue.main.async { [weak self] in
            self?.jiggler.start()
        }
    }
    
    @objc private func toggleStartStop() {
        if jiggler.isRunning {
            jiggler.stop()
        } else {
            jiggler.start()
        }
    }
    
    @objc private func setInterval(_ sender: NSMenuItem) {
        guard let sec = sender.representedObject as? Int else { return }
        jiggler.interval = TimeInterval(sec)
        refreshLabels()
        restartJigglerIfRunning()
    }
    
    @objc private func setDelta(_ sender: NSMenuItem) {
        guard let px = sender.representedObject as? Int else { return }
        jiggler.delta = CGFloat(px)
        refreshLabels()
    }
    
    @objc private func toggleStartAtLogin() {
        let now = LoginItemManager.isEnabled()
        LoginItemManager.setEnabled(!now)
        refreshLabels()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
