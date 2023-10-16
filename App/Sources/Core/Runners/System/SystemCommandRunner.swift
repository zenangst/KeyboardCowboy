import AXEssibility
import Cocoa
import Combine
import Dock
import Foundation
import MachPort
import Windows

final class SystemCommandRunner {
  var machPort: MachPortEventController?

  private var frontmostApplicationSubscription: AnyCancellable?
  private var subjectSubscription: AnyCancellable?
  private var flagSubscription: AnyCancellable?
  private var subject = PassthroughSubject<Void, Never>()

  private var allVisibleApplicationsInSpace: [WindowModel] = .init()
  private var visibleApplicationWindows: [WindowModel] = .init()
  private var visibleMostIndex: Int = 0

  private var frontMostApplicationWindows: [WindowAccessibilityElement] = .init()
  private var frontMostIndex: Int = 0

  private var frontmostApplication: RunningApplication = NSRunningApplication.current
  private var interactive: Bool = false

  private let applicationStore: ApplicationStore
  private let workspace: WorkspaceProviding

  init(_ applicationStore: ApplicationStore, workspace: WorkspaceProviding = NSWorkspace.shared) {
    self.applicationStore = applicationStore
    self.workspace = workspace
  }

  func subscribe(to publisher: Published<RunningApplication?>.Publisher) {
    frontmostApplicationSubscription = publisher
      .compactMap { $0 }
      .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
      .sink { [weak self]  in
        guard let self else { return }
        self.frontmostApplication = $0
        self.frontMostIndex = 0
        self.indexFrontmost($0)
        if self.interactive == false { self.index($0) }
      }
  }

  func subscribe(to publisher: Published<CGEventFlags?>.Publisher) {
    subjectSubscription = subject
      .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
      .sink { [weak self] in
        guard let self, self.interactive == false else { return }
        self.index(self.frontmostApplication)
      }
    flagSubscription = publisher
      .compactMap { $0 }
      .sink { [weak self] flags in
        guard let self else { return }
        self.interactive = flags != CGEventFlags.maskNonCoalesced
        if self.interactive == false {
          self.frontMostIndex = 0
          self.visibleMostIndex = 0
          self.subject.send()
        }
      }
  }

  func containsStandardModifierKeys(_ flags: CGEventFlags) -> Bool {
      let standardModifierKeys: [CGEventFlags] = [.maskShift, .maskControl, .maskAlternate, .maskCommand, .maskSecondaryFn]
      for modifierKey in standardModifierKeys {
          if flags.contains(modifierKey) {
              return true
          }
      }
      return false
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

        let collectionCount = collection.count

        guard collectionCount > 1 else { return }

        switch command.kind {
        case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal:
          visibleMostIndex += 1
          if visibleMostIndex >= collectionCount {
            visibleMostIndex = 0
          }
        default:
          visibleMostIndex -= 1
          if visibleMostIndex < 0 {
            visibleMostIndex = collectionCount - 1
          }
        }

        let window = collection[visibleMostIndex]
        let windowId = UInt32(window.id)
        let processIdentifier = pid_t(window.ownerPid.rawValue)
        let runningApplication = NSRunningApplication(processIdentifier: processIdentifier)
        let app = AppAccessibilityElement(processIdentifier)

        if let runningApplication = runningApplication {
          let options: NSApplication.ActivationOptions = [.activateIgnoringOtherApps]
          runningApplication.activate(options: options)

          if let bundleIdentifier = runningApplication.bundleIdentifier,
             bundleIdentifier != workspace.frontApplication?.bundleIdentifier,
             let application = applicationStore.application(for: bundleIdentifier) {
            let url = URL(fileURLWithPath: application.path)
            Task.detached { [workspace] in
              let configuration = NSWorkspace.OpenConfiguration()
              configuration.activates = true
              _ = try? await workspace.openApplication(at: url, configuration: configuration)
            }
          }
        }

        let axWindow = try app.windows().first(where: { $0.id == windowId })
        _ = await MainActor.run {
          axWindow?.performAction(.raise)
        }
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
        _ = await MainActor.run {
          window.performAction(.raise)
        }
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

  private func getWindows() -> [WindowModel] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .optionIncludingWindow, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private func index(_ runningApplication: RunningApplication) {
    let windowModels = getWindows()
    indexAllApplicationsInSpace(windowModels)
    indexVisibleApplications(windowModels)
    indexFrontmost(runningApplication)
  }

  private func indexAllApplicationsInSpace(_ models: [WindowModel]) {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 0, height: 0)
    let windowModels: [WindowModel] = models
      .filter {
        $0.id > 0 &&
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
        $0.id > 0 &&
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        !excluded.contains($0.ownerName)
      }

    visibleApplicationWindows = windowModels
  }

  private func indexFrontmost(_ frontMostApplication: RunningApplication) {
    let pid = frontmostApplication.processIdentifier
    let element = AppAccessibilityElement(pid)
    do {
      frontMostApplicationWindows = try element.windows()
        .filter({
          $0.id > 0 &&
          ($0.frame?.size.height ?? 0) > 20
        })
    } catch { }
  }
}
