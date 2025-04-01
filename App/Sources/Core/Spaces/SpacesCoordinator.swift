import AXEssibility
import Apps
import Carbon
import Combine
import Cocoa
import Foundation
import MachPort
import Windows

@MainActor
final class SpacesCoordinator {
  nonisolated(unsafe) private var restoreWindows: [SpaceWindow] = []

  fileprivate var windows: [Int32: SpaceWindow] = [:]
  fileprivate static var shared: SpacesCoordinator!

  private static var enabled: Bool = false

  private var closed: AccessibilityObserver?
  private var currentSpace: Space
  private var focus: AccessibilityObserver?
  private var spaces: [String: Space] = [:]
  private var subscription: AnyCancellable?
  private var windowCreated: AccessibilityObserver?

  let store: KeyCodesStore

  internal init(store: KeyCodesStore) {
    self.store = store
    let space = Space(id: "1", screen: NSScreen.main!, shouldIndex: true)
    currentSpace = space
    Self.shared = self
    spaces = [currentSpace.id: space]

    for spaceWindow in currentSpace.windows {
      self.windows[spaceWindow.id] = spaceWindow
      self.restoreWindows.append(spaceWindow)
    }
  }

  func intercept(_ machPortEvent: MachPortEvent) -> Bool {
    guard Self.enabled else { return false }

    let keyCode = Int(machPortEvent.keyCode)
    let keys = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4]
    let matchKey = keys.contains(keyCode)

    guard matchKey && machPortEvent.flags.contains(.maskSecondaryFn) else {
      return false
    }

    machPortEvent.result = nil

    guard machPortEvent.type == .keyDown && machPortEvent.isRepeat == false else {
      return true
    }

    let spaceKey: String = if  keyCode == kVK_ANSI_4 {
      "4"
    } else if keyCode == kVK_ANSI_3 {
      "3"
    } else if keyCode == kVK_ANSI_2 {
      "2"
    } else {
      "1"
    }

    if machPortEvent.flags.contains(.maskCommand) {
      moveCurrentWindow(to: spaceKey)
    } else {
      swap(to: spaceKey)
    }

    return true
  }

  func swap(to spaceKey: String) {
    guard spaceKey != currentSpace.id else {
      return
    }


    let nextSpace = createSpaceIfNeeded(for: spaceKey)
    nextSpace.windows.forEach { $0.show() }

    let previousSpace = currentSpace
    previousSpace.windows.forEach { $0.hide() }

    if let last = nextSpace.windows.last {
      last.ref?.main = true
      last.ref?.performAction(.raise)
      NSRunningApplication.focusOnPid(pid_t(last.processIdentifier))
    }

    let capsule = CapsuleNotificationWindow.shared
    capsule.open()
    capsule.publish("Swap to \(nextSpace.id)", state: .success)

    currentSpace = nextSpace

    print("space: ", currentSpace.id)
    for window in currentSpace.windows {
      print(window.ref)
    }
  }

  func moveCurrentWindow(to spaceKey: String) {
    let previousSpace = currentSpace
    let app = AppAccessibilityElement(UserSpace.shared.frontmostApplication.ref.processIdentifier)

    guard let focusedWindow = try? app.focusedWindow(),
          let targetWindow = previousSpace.windows.first(where: { $0.ref?.id == focusedWindow.id }) else { return }

    previousSpace.remove(targetWindow)
    previousSpace.windows.forEach { $0.hide() }

    let nextSpace = createSpaceIfNeeded(for: spaceKey)
    nextSpace.add(targetWindow)
    nextSpace.windows.forEach {
      $0.space = nextSpace
      $0.show()
    }

    targetWindow.ref?.main = true
    targetWindow.ref?.performAction(.raise)

    NSRunningApplication.focusOnPid(UserSpace.shared.frontmostApplication.ref.processIdentifier)

    let capsule = CapsuleNotificationWindow.shared
    capsule.open()
    capsule.publish("Move window \(focusedWindow.id) to \(nextSpace.id)", state: .success)

    currentSpace = nextSpace
  }

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    guard Self.enabled else { return }

    subscription = publisher
      .sink { [weak self] application in
        self?.configureApplicationObservation(for: application.ref)

        let app = AppAccessibilityElement(application.ref.processIdentifier)

        if !application.ref.isFinishedLaunching {
          Task { @MainActor in
            var waiting: Bool = true
            var retries: Int = 20
            while waiting {
              if application.ref.isFinishedLaunching, let focusedWindow = try? app.focusedWindow() {
                waiting = false
                self?.onFocus(focusedWindow)
              } else {
                retries = retries - 1

                if retries == 0 {
                  waiting = false
                } else {
                  try? await Task.sleep(for: .milliseconds(100))
                }
              }
            }
          }
        } else {
          guard let focusedWindow = try? app.focusedWindow() else { return }
          self?.onFocus(focusedWindow)
        }
      }
  }

  private func createSpaceIfNeeded(for spaceKey: String) -> Space {
    if let existingSpace = spaces[spaceKey] {
      return existingSpace
    } else {
      let newSpace = Space(id: spaceKey, screen: NSScreen.main!, shouldIndex: false)
      spaces[spaceKey] = newSpace
      return newSpace
    }
  }

  private func configureApplicationObservation(for runningApplication: any RunningApplication) {
    let application = AppAccessibilityElement(runningApplication.processIdentifier)
    windowCreated?.removeObserver()
    windowCreated = application.observe(.windowCreated, element: application.reference,
                                        id: UUID(), callback: { observer, element, notification, data in
      guard let window = WindowAccessibilityElement(element),
            window.subrole == kAXStandardWindowSubrole else { return }

      let coordinator = SpacesCoordinator.shared!
      let currentSpace = coordinator.currentSpace

      if let app = window.app, let processIdentifier = app.pid {
        let windowId = Int32(window.id)

        guard coordinator.windows[windowId] == nil else { return }

        let spaceWindow = SpaceWindow(id: windowId, processIdentifier: Int(processIdentifier),
                                      space: currentSpace, ref: window)
        currentSpace.add(spaceWindow)
        coordinator.windows[windowId] = spaceWindow
      } else {
        print("unable to add window", window, "to", currentSpace.id)
      }
    })

    closed?.removeObserver()
    closed = application.observe(.closed, element: application.reference,
                                 id: UUID(), callback: { observer, element, notification, data in
      let coordinator = SpacesCoordinator.shared!
      for (_, space) in coordinator.spaces {
        let invalidIds = space.clean()

        coordinator.restoreWindows.removeAll(where: { invalidIds.contains($0.id)})
        for invalidId in invalidIds {
          coordinator.windows[invalidId] = nil
        }
      }
    })

    focus?.removeObserver()
    focus = application.observe(.focusedWindowChanged, element: application.reference,
                                id: UUID(), callback: { observer, element, notification, data in
      guard let window = WindowAccessibilityElement(element) else { return }

      SpacesCoordinator.shared.onFocus(window)
    })
  }

  private func onFocus(_ window: WindowAccessibilityElement) {
    guard window.subrole == kAXStandardWindowSubrole else { return }

    let coordinator =  SpacesCoordinator.shared!
    let spaces = Array(coordinator.spaces.values)
    let currentSpace = coordinator.currentSpace
    let windowId = Int32(window.id)

    if let spaceWindow = spaces
      .flatMap(\.windows)
      .first(where: { $0.ref?.reference == window.reference }) {
      if spaceWindow.space!.id != currentSpace.id {
        let nextSpace = spaceWindow.space!

        nextSpace.windows.forEach { $0.show() }
        currentSpace.windows.forEach { $0.hide() }
        coordinator.currentSpace = nextSpace

        spaceWindow.ref?.main = true
        spaceWindow.ref?.performAction(.raise)

        NSRunningApplication.focusOnPid(pid_t(spaceWindow.processIdentifier))

      }
    } else if coordinator.windows[windowId] == nil,
              let processIdentifier = window.app?.pid {
      let spaceWindow = SpaceWindow(id: Int32(window.id), processIdentifier: Int(processIdentifier),
                                    space: currentSpace, ref: window)
      currentSpace.add(spaceWindow)
      coordinator.windows[windowId] = spaceWindow
    }
  }
}

@MainActor
final class Space: Identifiable {
  let id: String
  var screen: NSScreen
  private(set) var windows: [SpaceWindow] = []

  init(id: String, screen: NSScreen, shouldIndex: Bool) {
    self.id = id
    self.screen = screen

    guard shouldIndex else { return }

    let windows = index([.excludeDesktopElements, .optionOnScreenOnly], in: self, on: NSScreen.main!)
    for spaceWindow in windows {
      let processIdentifier = spaceWindow.processIdentifier
      let pid_t: pid_t = Int32(processIdentifier)
      let application = AppAccessibilityElement(pid_t)

      if let refWindow = try? application.windows().first(where: { $0.id == spaceWindow.id }) {
        spaceWindow.ref = refWindow

        let targetRect = screen.frame.insetBy(dx: 2, dy: 2)
        if refWindow.frame?.intersects(targetRect) == true {
          self.windows.append(spaceWindow)
        }
      }
    }
  }

  func clean() -> [Int32] {
    let invalidIds = windows.filter { $0.ref?.id == 0 }
      .map(\.id)
    windows.removeAll(where: { invalidIds.contains($0.id) })
    return invalidIds
  }

  func add(_ window: SpaceWindow) {
    assert(self.windows.contains(where: { $0.id == window.id }) == false)
    self.windows.append(window)
  }

  func remove(_ window: SpaceWindow) {
    assert(self.windows.contains(where: { $0.id == window.id }) == true)
    self.windows.removeAll(where: { $0.id == window.id })
  }

  private func index(_ options: CGWindowListOption, in space: Space, on screen: NSScreen) -> [SpaceWindow] {
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 300, height: 200)
    let targetRect = screen.frame.insetBy(dx: 2, dy: 2)
    let windows: [WindowModel] = windowModels
      .filter {
        $0.id > 0 &&
        $0.ownerName != "borders" &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        $0.alpha == 1 &&
        !excluded.contains($0.ownerName) &&
        $0.rect.intersects(targetRect)
      }

    return windows.map { windowModel in
      SpaceWindow(
        id: Int32(windowModel.id),
        processIdentifier: windowModel.ownerPid.rawValue,
        space: space,
        ref: nil
      )
    }
  }
}

final class SpaceWindow: Identifiable {
  weak var space: Space?
  var ref: WindowAccessibilityElement?
  var restoreRect: CGRect?

  let id: Int32
  let processIdentifier: Int

  init(id: Int32, processIdentifier: Int, space: Space, ref: WindowAccessibilityElement?) {
    self.id = id
    self.processIdentifier = processIdentifier
    self.space = space
    self.ref = ref
  }

  func hide() {
    guard let frame = ref?.frame, restoreRect == nil else { return }
    restoreRect = frame

    let currentScreen = NSScreen.main!
    let origin = CGPoint(
      x: currentScreen.frame.width - 0.25,
      y: currentScreen.frame.height
    )

    ref?.position = origin
  }

  func show() {
    guard let restoreRect else { return }
    ref?.frame = restoreRect
    self.restoreRect = nil
  }
}

extension NSRunningApplication {
  static func focusOnPid(_ processIdentifier: pid_t) {
    let runningApp = NSRunningApplication(processIdentifier: processIdentifier)
    if #available(macOS 14.0, *) {
      runningApp?.activate(from: NSWorkspace.shared.frontmostApplication!, options: .activateIgnoringOtherApps)
    } else {
      runningApp?.activate(options: .activateIgnoringOtherApps)
    }
  }
}
