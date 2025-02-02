import Apps
import AXEssibility
import Bonzai
import Carbon
import Cocoa
import Combine
import MachPort
import SwiftUI
import Windows

@MainActor
final class WindowSwitcherWindow: NSObject, NSWindowDelegate {
  private lazy var publisher: WindowSwitcherPublisher = .init(items: [], selections: [])
  private var subscription: AnyCancellable?
  private var window: NSWindow?
  private var keyMonitor: Any?
  private var windows: [WindowModel] = []
  private var filterTask: Task<Void, any Error>?
  private var shouldCloseOnResignKey: Bool = false

  private let bundledRunner: BundledCommandRunner
  private let commandRunner: CommandRunner

  init(commandRunner: CommandRunner) {
    self.bundledRunner = commandRunner.runners.bundled
    self.commandRunner = commandRunner
    super.init()
  }

  func open(_ snapshot: UserSpace.Snapshot) {
    if window != nil {
      if let menubarOwner = NSWorkspace.shared.runningApplications.first(where: { $0.ownsMenuBar == true }),
         let bundleURL = menubarOwner.bundleURL {
        NSWorkspace.shared.open(bundleURL)
      }
      window?.close()
      return
    }

    refreshWindows()

    let window = createWindow()
    window.orderFrontRegardless()
    window.makeKeyAndOrderFront(nil)
    window.center()

    self.window = window
    self.subscription = subscribe(to: publisher.$query)
  }

  func windowDidBecomeKey(_ notification: Notification) {
    let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .keyDown, .flagsChanged]) { [weak self] event in
      guard let self else {
        return event
      }
      return handleKeyDown(event)
    }
    self.keyMonitor = keyMonitor
  }

  func windowDidResignKey(_ notification: Notification) {
    removeMonitorIfNeeded()
    if shouldCloseOnResignKey {
      window?.close()
    }
  }

  func windowWillClose(_ notification: Notification) {
    self.window = nil
  }

  // MARK: Private methods

  private func removeMonitorIfNeeded() {
    if let keyMonitor {
      NSEvent.removeMonitor(keyMonitor)
    }
  }

  private func refreshWindows(updateSelection: Bool = true) {
    Task(priority: .userInitiated) {
      if !windows.isEmpty {
        self.filter(windows, query: publisher.query)
      }

      let onScreenWindows = WindowStore.shared.getWindows(onScreen: true)
      let ids = Set(onScreenWindows.map(\.windowNumber))
      let notOnScreenWindows = WindowStore.shared.getWindows(onScreen: false)
        .filter({ !ids.contains($0.windowNumber) })
      let rawWindows = onScreenWindows + notOnScreenWindows
      let windows = WindowStore.shared.allApplicationsInSpace(rawWindows, onScreen: false, sorted: false)

      if windows != self.windows {
        self.windows = windows
      }
    }
  }

  private func subscribe(to target: Published<String>.Publisher) -> AnyCancellable {
    target
      .dropFirst()
      .debounce(for: .milliseconds(75), scheduler: RunLoop.main)
      .sink { [weak self] newValue in
      guard let self else { return }
      self.filter(windows, query: newValue)
    }
  }

  private func handleKeyDown(_ event: NSEvent) -> NSEvent? {

    if event.type == .flagsChanged {
      if event.modifierFlags.contains(.command) {
        publisher.modifiers = .command
      } else if publisher.modifiers != [] {
        publisher.modifiers = []
      }
    }

    let keyCode = Int(event.keyCode)
    switch keyCode {
    case kVK_ANSI_Q:
      if event.modifierFlags.contains(.command) {
        if !event.isARepeat,
            event.type == .keyDown, let currentSelection = getCurrentSelection(),
           let runningApplication = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == currentSelection.app.bundleIdentifier }) {

          if currentSelection.app.bundleIdentifier == NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            shouldCloseOnResignKey = false
          }

          if runningApplication.terminate() {
            Task.detached { [weak self] in
              var waiting = true
              var timeout = 5
              while waiting {
                if NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == currentSelection.app.bundleIdentifier }) == false {
                  waiting = false
                  await self?.refreshWindows(updateSelection: false)
                  await MainActor.run { [weak self] in
                    self?.shouldCloseOnResignKey = true
                    self?.window?.orderFrontRegardless()
                    self?.window?.makeKeyAndOrderFront(nil)
                  }
                }
                timeout -= 1

                try await Task.sleep(for: .milliseconds(100))

                if timeout <= 0 {
                  waiting = false
                }
              }
            }
          }
        }
        return nil
      }
      return event
    case kVK_UpArrow:
      guard event.type == .keyDown, let currentIndex = getCurrentSelectedIndex() else { return nil }
      let nextIndex = currentIndex - 1
      if nextIndex >= 0 {
        publisher.publish([publisher.items[nextIndex].id])
      } else if let last = publisher.items.last {
        publisher.publish([last.id])
      }
      return nil
    case kVK_Return:
      guard event.type == .keyDown, let currentIndex = getCurrentSelectedIndex() else { return nil }

      let currentItem = publisher.items[currentIndex]

      switch currentItem.kind {
      case .application:
        NSWorkspace.shared.open(URL(fileURLWithPath: currentItem.app.path))
      case .window(let window, _):
        if event.modifierFlags.contains(.command) {
          Task {
            let bundledCommand = BundledCommand(.appFocus(.init(bundleIdentifer: currentItem.app.bundleIdentifier, hideOtherApps: false, tiling: .arrangeDynamicQuarters)), meta: .init())
            let command = Command.bundled(bundledCommand)
            if let emptyEvent = MachPortEvent.empty() {
              var runtimeDictionary: [String: String] = [:]
              _ = try await bundledRunner.run(
                bundledCommand: bundledCommand,
                command: command,
                commandRunner: commandRunner,
                snapshot: UserSpace.shared.snapshot(resolveUserEnvironment: false),
                machPortEvent: emptyEvent,
                checkCancellation: false,
                repeatingEvent: false,
                runtimeDictionary: &runtimeDictionary
              )
            }
          }
        } else {
          window.performAction(.raise)
          NSWorkspace.shared.open(URL(fileURLWithPath: currentItem.app.path))
        }
      }

      window?.close()
      return nil
    case kVK_Escape:
      window?.close()

      if let menubarOwner = NSWorkspace.shared.runningApplications.first(where: { $0.ownsMenuBar == true }),
         let bundleURL = menubarOwner.bundleURL {
        NSWorkspace.shared.open(bundleURL)
      }
      return nil
    case kVK_DownArrow:
      guard event.type == .keyDown, let currentIndex = getCurrentSelectedIndex() else { return nil }

      let nextIndex = currentIndex + 1
      if nextIndex <= publisher.items.count - 1 {
        publisher.publish([publisher.items[nextIndex].id])
      } else if let first = publisher.items.first {
        publisher.publish([first.id])
      }

      return nil
    default:
      return event
    }
  }

  private func getCurrentSelection() -> WindowSwitcherView.Item? {
    guard let currentIndex = getCurrentSelectedIndex() else {
      return nil
    }

    return publisher.items[currentIndex]
  }

  private func getCurrentSelectedIndex() -> Int? {
    guard let currentSelection = publisher.selections.first,
          let currentIndex = publisher.items.firstIndex(where: { $0.id == currentSelection }) else {
      return nil
    }

    return currentIndex
  }

  private func filter(_ windows: [WindowModel], query: String, updateSelection: Bool = true) {
    let items = self.createItems(from: windows)

    if query.isEmpty {
      if publisher.items != items {
        publisher.publish(items)
        if let initialSelections = items.prefix(2).last?.id {
          publisher.publish([initialSelections])
        }
      }
    } else {
      let words = Set(publisher.query.components(separatedBy: " ")
        .map(\.localizedLowercase))
      let currentSelection = publisher.selections
      var needsSelectionUpdate = true
      var windowBundleIdentifiers = Set<String>()

      var filtered = items.filter { item in
        for word in words {
          if item.title.localizedLowercase.contains(word) || item.app.displayName.localizedLowercase.contains(word) {
            windowBundleIdentifiers.insert(item.app.bundleIdentifier)
            if currentSelection.contains(item.id) {
              needsSelectionUpdate = false
            }
            return true
          }
        }

        return false
      }

      let openApps = Set(filtered.map { $0.app })
      let apps = ApplicationStore.shared.applications
      let matchingApps: [Application]

      if filtered.isEmpty {
          matchingApps = apps.filter { app in
            if windowBundleIdentifiers.contains(app.bundleIdentifier) {
              return false
            }

            if openApps.contains(app) { return false }

            for word in words {
              return app.displayName.localizedLowercase.contains(word)
            }
            return false
          }
      } else if !query.isEmpty {
        matchingApps = apps.filter { app in
          app.displayName.lowercased() == query.lowercased() &&
          !windowBundleIdentifiers.contains(app.bundleIdentifier)
        }
      } else {
        matchingApps = []
      }

      let appItems = matchingApps.map { app in
          WindowSwitcherView.Item(id: app.path, title: app.displayName,
                                  app: app, kind: .application,
                                  hints: WindowSwitcherView.Item.Hints(commandKey: ""))
        }
      filtered.append(contentsOf: appItems)

      if filtered != publisher.items {
        publisher.publish(filtered)
      }

      if updateSelection, needsSelectionUpdate, let first = filtered.first?.id {
        publisher.selections = [first]
      }
    }
  }

  private func createItems(from windows: [WindowModel]) -> [WindowSwitcherView.Item]
  { var items = [WindowSwitcherView.Item]()
    for window in windows {
      guard let process = NSWorkspace.shared.runningApplications.first(where: {
        $0.processIdentifier == window.ownerPid.rawValue
      }),
            let bundleIdentifier = process.bundleIdentifier,
            let app = ApplicationStore.shared.application(for: bundleIdentifier) else {
        continue
      }

      guard let axWindow = try? AppAccessibilityElement(process.processIdentifier)
        .windows()
        .first(where: { $0.id == window.id }) else {
        continue
      }

      let item = WindowSwitcherView.Item(
        id: "\(window.id)",
        title: axWindow.title ?? window.name,
        app: app,
        kind: .window(window: axWindow, onScreen: window.isOnScreen),
        hints: WindowSwitcherView.Item.Hints(commandKey: "Focus on \(app.displayName)")
      )

      items.append(item)
    }

    return items
  }

  private func createWindow() -> NSWindow {
    let styleMask: NSWindow.StyleMask = [
      .titled,
      .fullSizeContentView,
      .nonactivatingPanel
    ]

    let window = ZenSwiftUIPanel(styleMask: styleMask, overrides: .init(canBecomeKey: true, canBecomeMain: true)) {
      WindowSwitcherView(publisher: publisher)
    }

    window.animationBehavior = .none

    let size = window.hostingController.sizeThatFits(in: .init(width: 480, height: 360))
    window.setFrame(NSRect(origin: .zero, size: size), display: false)

    window.backgroundColor = .clear
    window.collectionBehavior = []
    window.delegate = self
    window.ignoresMouseEvents = false
    window.isMovable = true
    window.isMovableByWindowBackground = true
    window.hidesOnDeactivate = false
    window.isFloatingPanel = true
    window.level = .floating
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true

    return window
  }
}
