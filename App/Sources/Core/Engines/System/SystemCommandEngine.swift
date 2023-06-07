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

  private var allVisibleApplicationsInSpace: [WindowModel] = .init()
  private var visibleApplicationWindows: [WindowModel] = .init()
  private var visibleMostIndex: Int = 0

  private var frontMostApplicationWindows: [WindowAccessibilityElement] = .init()
  private var frontMostIndex: Int = 0

  func subscribe(to publisher: Published<CGEventFlags?>.Publisher) {
    subjectSubscription = publisher
      .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
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

  func run(_ command: SystemCommand) async throws {
    Task { @MainActor in
      switch command.kind {
      case .moveFocusToNextWindow, .moveFocusToPreviousWindow,
           .moveFocusToNextWindowGlobal, .moveFocusToPreviousWindowGlobal:
        let collection = command.kind == .moveFocusToNextWindowGlobal ||
        command.kind == .moveFocusToPreviousWindowGlobal
        ? allVisibleApplicationsInSpace
        : visibleApplicationWindows
        
        guard collection.count > 1 else { return }
        if case .moveFocusToNextWindow = command.kind {
          visibleMostIndex += 1
          if visibleMostIndex >= collection.count {
            visibleMostIndex = 0
          }
        } else if case .moveFocusToNextWindowGlobal = command.kind {
          visibleMostIndex += 1
          if visibleMostIndex >= collection.count {
            visibleMostIndex = 0
          }
        } else {
          visibleMostIndex -= 1
          if visibleMostIndex < 0 {
            visibleMostIndex = collection.count - 1
          }
        }
        let window = collection[visibleMostIndex]
        let windowId = UInt32(window.id)
        let processIdentifier = pid_t(window.ownerPid.rawValue)
        let runningApplication = NSRunningApplication(processIdentifier: processIdentifier)
        let app = AppAccessibilityElement(processIdentifier)
        let axWindow = try app.windows().first(where: {
          $0.id == windowId
        })

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
  }

  // MARK: - Private methods

  private func index() {
    let options: CGWindowListOption = [.optionOnScreenOnly, .optionIncludingWindow, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])

    frontMostIndex = 0

    indexAllApplicationsInSpace(windowModels)
    indexVisibleApplications(windowModels)
    indexFrontmost()
  }

  private func indexAllApplicationsInSpace(_ models: [WindowModel]) {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 0, height: 0)
    let windowModels: [WindowModel] = models
      .filter {
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        !excluded.contains($0.ownerName)
      }
      .sorted { lhs, rhs in
        lhs.rect.origin.y < rhs.rect.origin.y
      }
    allVisibleApplicationsInSpace = windowModels
  }

  private func indexVisibleApplications(_ models: [WindowModel]) {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 300, height: 300)
    let windowModels: [WindowModel] = models
      .filter {
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        !excluded.contains($0.ownerName)
      }

    visibleApplicationWindows = windowModels
    visibleMostIndex = 0
  }

  private func indexFrontmost() {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else { return }
    let pid = frontmostApplication.processIdentifier
    let element = AppAccessibilityElement(pid)
    do {
      frontMostApplicationWindows = try element.windows()
    } catch { }
  }
}
