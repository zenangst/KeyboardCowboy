import AXEssibility
import Cocoa
import Combine
import Dock
import Foundation
import MachPort
import Windows

final class SystemCommandEngine {
  var machPort: MachPortEventController?

  private var subjectSubscription: AnyCancellable?
  private var flagSubscription: AnyCancellable?
  private var subject = PassthroughSubject<Void, Never>()

  private var visibleApplicationWindows: [WindowModel] = .init()
  private var visibleMostIndex: Int = 0

  private var frontMostApplicationWindows: [WindowAccessibilityElement] = .init()
  private var frontMostIndex: Int = 0

  func subscribe(to publisher: Published<CGEventFlags?>.Publisher) {
    indexVisibleApplications()
    indexFrontmost()

    subjectSubscription = publisher
      .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
      .sink { [weak self] flags in
        guard let self else { return }
        self.index()
      }

    flagSubscription = publisher
      .sink { [weak self] flags in
        guard let self else { return }

        // TODO: This should not be bound to `.maskShift`
        guard flags == CGEventFlags.maskNonCoalesced || flags?.contains(.maskShift) == false else { return }
        self.subject.send()
      }
  }

  func index() {
    self.indexVisibleApplications()
    self.indexFrontmost()
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
      let processIdentifier = pid_t(window.ownerPid.rawValue)
      let runningApplication = NSRunningApplication(processIdentifier: processIdentifier)
      let app = AppAccessibilityElement(processIdentifier)
      let axWindow = try app.windows().first(where: { $0.id == windowId })
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
      Dock.run(.showDesktop)
    case .applicationWindows:
      Dock.run(.applicationWindows)
    case .missionControl:
      Dock.run(.missionControl)
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
    do {
      frontMostApplicationWindows = try element.windows()
      frontMostIndex = 0
    } catch { }
  }
}
