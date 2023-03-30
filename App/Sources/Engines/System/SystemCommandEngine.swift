import AXEssibility
import Cocoa
import Combine
import Foundation
import MachPort
import Windows

final class SystemCommandEngine {
  private var subscription: AnyCancellable?

  private var visibleApplicationWindows: [WindowModel] = .init()
  private var visibleMostIndex: Int = 0

  private var frontMostApplicationWindows: [WindowAccessibilityElement] = .init()
  private var frontMostIndex: Int = 0

  func subscribe(to publisher: Published<CGEventFlags?>.Publisher) {
    indexVisibleApplications()
    indexFrontmost()

    subscription = publisher
      .sink { [weak self] flags in
        guard let self else { return }

        // TODO: This should not be bound to `.maskShift`
        guard flags == CGEventFlags.maskNonCoalesced || flags?.contains(.maskShift) == false else { return }
        self.indexVisibleApplications()
        self.indexFrontmost()
      }
  }

  func run(_ command: SystemCommand) async throws {
    switch command.kind {
    case .moveFocusToNextWindow, .moveFocusToPreviousWindow:
      guard visibleApplicationWindows.count > 1 else { return }
      if case .moveFocusToNextWindow = command.kind {
        visibleMostIndex += 1
        if visibleMostIndex >= visibleApplicationWindows.count {
          visibleMostIndex = 0
        }
      } else {
        visibleMostIndex -= 1
        if visibleMostIndex < 0 {
          visibleMostIndex = visibleApplicationWindows.count - 1
        }
      }
      let window = visibleApplicationWindows[visibleMostIndex]
      let windowId = UInt32(window.id)
      let processIdentifier = window.ownerPid.pid
      let runningApplication = NSRunningApplication(processIdentifier: processIdentifier)
      let app = AppAccessibilityElement(processIdentifier)
      let axWindow = app.windows.first(where: { $0.id == windowId })
      runningApplication?.activate(options: .activateIgnoringOtherApps)
      axWindow?.performAction(.raise)
    case .moveFocusToNextWindowFront, .moveFocusToPreviousWindowFront:
      guard frontMostApplicationWindows.count > 1 else { return }
      if case .moveFocusToNextWindowFront = command.kind {
        frontMostIndex += 1
        if frontMostIndex >= frontMostApplicationWindows.count {
          frontMostIndex = 0
        }
      } else {
        frontMostIndex -= 1
        if frontMostIndex < 0 {
          frontMostIndex = frontMostApplicationWindows.count - 1
        }
      }

      let window = frontMostApplicationWindows[frontMostIndex]
      window.performAction(.raise)
    case .showDesktop:
      coreDockSendNotification("com.apple.showdesktop.awake")
    case .applicationWindows:
      coreDockSendNotification("com.apple.expose.front.awake")
    case .missionControl:
      coreDockSendNotification("com.apple.expose.awake")
    }
  }

  // Dispatch this invokation async so that the loop doesn't get stuck and the connection
  // to the mach port is invalidated.
  private func coreDockSendNotification(_ string: String) {
    DispatchQueue.global(qos: .userInitiated).async {
      CoreDockSendNotification(string as CFString, 0)
    }
  }

  private func indexVisibleApplications() {
    let excluded = ["WindowManager", "Window Server"]
    let options: CGWindowListOption = [.optionOnScreenOnly, .optionIncludingWindow, .excludeDesktopElements]
    let minimumSize = CGSize(width: 300, height: 300)
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
      .filter { !excluded.contains($0.ownerName) }
      .filter {
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height
      }
      .filter(\.isOnScreen)

    visibleApplicationWindows = windowModels
    visibleMostIndex = 0
  }

  private func indexFrontmost() {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else { return }
    let pid = frontmostApplication.processIdentifier
    let element = AppAccessibilityElement(pid)
    self.frontMostApplicationWindows = element.windows
    self.frontMostIndex = 0
  }
}
