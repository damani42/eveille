import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private let session = AwakeSession()
  private var statusItem: NSStatusItem!
  private let menu = NSMenu()
  private let summary = NSMenuItem(title: "", action: nil, keyEquivalent: "")
  private let toggle = NSMenuItem(title: "", action: #selector(toggleAwake), keyEquivalent: "")
  private let display = NSMenuItem(
    title: "Keep the display on", action: #selector(toggleDisplay), keyEquivalent: "")
  private var durationItems: [NSMenuItem] = []
  private var ticker: Timer?
  private var keepDisplayOn = true
  private var duration = 0
  private let choices: [(String, Int)] = [
    ("Unlimited", 0), ("30 minutes", 1800), ("1 hour", 3600),
    ("2 hours", 7200), ("4 hours", 14400),
  ]

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Reopening the app brings the existing menu forward.
    let others = NSRunningApplication.runningApplications(
      withBundleIdentifier: Bundle.main.bundleIdentifier ?? "io.github.damani42.eveille")
    if let other = others.first(where: {
      $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
    }) {
      other.activate(options: [])
      NSApp.terminate(nil)
      return
    }
    let defaults = UserDefaults.standard
    if defaults.object(forKey: "keepDisplayOn") != nil {
      keepDisplayOn = defaults.bool(forKey: "keepDisplayOn")
    }
    let savedDuration = defaults.integer(forKey: "duration")
    duration = choices.contains(where: { $0.1 == savedDuration }) ? savedDuration : 0
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    menu.delegate = self
    menu.autoenablesItems = false
    let title = NSMenuItem(title: "Eveille", action: nil, keyEquivalent: "")
    title.isEnabled = false
    menu.addItem(title)
    summary.isEnabled = false
    menu.addItem(summary)
    menu.addItem(.separator())
    toggle.target = self
    display.target = self
    menu.addItem(toggle)
    menu.addItem(display)
    let durationMenu = NSMenu()
    durationMenu.autoenablesItems = false
    for (label, seconds) in choices {
      let item = NSMenuItem(title: label, action: #selector(selectDuration(_:)), keyEquivalent: "")
      item.tag = seconds
      item.target = self
      durationMenu.addItem(item)
      durationItems.append(item)
    }
    let durationRoot = NSMenuItem(title: "Duration", action: nil, keyEquivalent: "")
    durationRoot.submenu = durationMenu
    menu.addItem(durationRoot)
    menu.addItem(.separator())
    let help = NSMenuItem(title: "About Eveille…", action: #selector(showAbout), keyEquivalent: "")
    help.target = self
    menu.addItem(help)
    let quit = NSMenuItem(title: "Quit Eveille", action: #selector(quitApp), keyEquivalent: "q")
    quit.target = self
    menu.addItem(quit)
    statusItem.menu = menu
    ticker = Timer(
      timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    RunLoop.main.add(ticker!, forMode: .common)
    start()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  {
    statusItem?.button?.performClick(nil)
    return false
  }

  private func start() {
    do {
      try session.start(keepDisplayOn: keepDisplayOn, duration: TimeInterval(duration))
    } catch { showError(error) }
    refresh()
  }

  @objc private func toggleAwake() {
    if session.isActive {
      session.stop()
      refresh()
    } else {
      start()
    }
  }

  @objc private func toggleDisplay() {
    let newValue = !keepDisplayOn
    do {
      if session.isActive { try session.setDisplayMode(keepDisplayOn: newValue) }
      keepDisplayOn = newValue
      UserDefaults.standard.set(newValue, forKey: "keepDisplayOn")
    } catch { showError(error) }
    refresh()
  }

  @objc private func selectDuration(_ sender: NSMenuItem) {
    duration = sender.tag
    UserDefaults.standard.set(duration, forKey: "duration")
    session.setDuration(TimeInterval(duration))
    refresh()
  }

  @objc private func tick() {
    session.expireIfNeeded()
    refresh()
  }

  private func refresh() {
    let active = session.isActive
    let symbol = active ? "sun.max.fill" : "moon.zzz"
    let image = NSImage(
      systemSymbolName: symbol, accessibilityDescription: active ? "Mac kept awake" : "Normal sleep"
    )
    image?.isTemplate = true
    statusItem.button?.image = image
    statusItem.button?.toolTip =
      active ? "Eveille — keeping your Mac awake" : "Eveille — normal sleep"
    toggle.title = active ? "Turn off keep-awake" : "Keep Mac awake"
    toggle.state = active ? .on : .off
    display.state = keepDisplayOn ? .on : .off
    for item in durationItems { item.state = item.tag == duration ? .on : .off }
    if active, let endDate = session.endDate {
      let minutes = max(1, Int(ceil(endDate.timeIntervalSinceNow / 60)))
      summary.title = "Active · \(minutes) min remaining"
    } else {
      summary.title = active ? "Active · unlimited" : "Inactive · normal sleep"
    }
  }

  func menuWillOpen(_ menu: NSMenu) { tick() }

  @objc private func showAbout() {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = "Eveille"
    alert.informativeText =
      "Keep your Mac awake during long tasks.\n\nKeep-awake starts when you open the app. Turn it off from the menu or quit to restore normal sleep.\n\nClosing the lid, manual sleep and manual locking remain available. Other apps may still need your input.\n\nVersion 1.0.0 · works entirely offline."
    alert.addButton(withTitle: "Got it")
    alert.runModal()
  }

  private func showError(_ error: Error) {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert(error: error)
    alert.runModal()
  }

  @objc private func quitApp() { NSApp.terminate(nil) }
  func applicationWillTerminate(_ notification: Notification) {
    ticker?.invalidate()
    session.stop()
  }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
