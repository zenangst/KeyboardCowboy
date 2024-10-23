import Apps
import AXEssibility
import Cocoa
import Combine
import Dock
import Foundation
import MachPort
import Windows

struct WindowStoreSnapshot: @unchecked Sendable {
  let frontmostApplicationWindows: [WindowAccessibilityElement]
  let visibleWindowsInStage: [WindowModel]
  let visibleWindowsInSpace: [WindowModel]

  init(frontmostApplicationWindows: [WindowAccessibilityElement],
       visibleWindowsInStage: [WindowModel],
       visibleWindowsInSpace: [WindowModel]) {
    self.frontmostApplicationWindows = frontmostApplicationWindows
    self.visibleWindowsInStage = visibleWindowsInStage
    self.visibleWindowsInSpace = visibleWindowsInSpace
  }
}

final class WindowStore: @unchecked Sendable {
  final class Subscriptions {
    var flagsChange: AnyCancellable?
    var passthrough = PassthroughSubject<Void, Never>()
    var subject: AnyCancellable?
    var frontmostApplication: AnyCancellable?
  }

  final class State: @unchecked Sendable {
    var appAccessibilityElement: AppAccessibilityElement
    var frontmostApplication: UserSpace.Application
    var frontmostIndex: Int = 0
    var visibleMostIndex: Int = 0
    var interactive: Bool = false
    var frontmostApplicationWindows: [WindowAccessibilityElement] = .init()
    var visibleWindowsInStage: [WindowModel] = .init()
    var visibleWindowsInSpace: [WindowModel] = .init()

    @MainActor
    init() {
      let pid = UserSpace.Application.current.ref.processIdentifier
      self.appAccessibilityElement = AppAccessibilityElement(pid)
      self.frontmostApplication = .current
    }
  }

  @Published private(set) var windows: [WindowModel] = []

  private let subscriptions: Subscriptions = .init()
  let state: State

  @MainActor
  static let shared: WindowStore = .init()

  @MainActor
  private init() {
    self.state = State()
  }

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    subscriptions.frontmostApplication = publisher
      .compactMap { $0 }
      .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
      .sink { [weak self, state] application in
        guard let self else { return }

        let pid = application.ref.processIdentifier
        state.appAccessibilityElement = AppAccessibilityElement(pid)
        state.frontmostApplication = application
        state.frontmostIndex = 0
        if state.interactive == false {
          self.index(application)
        } else {
          self.indexFrontmost()
        }
      }
  }

  func subscribe(to publisher: Published<CGEventFlags?>.Publisher) {
    subscriptions.subject = subscriptions.passthrough
      .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
      .sink { [weak self, state] in
        guard let self, state.interactive == false else { return }
        self.index(state.frontmostApplication)
      }
    subscriptions.flagsChange = publisher
      .compactMap { $0 }
      .sink { [state, subscriptions] flags in
        state.interactive = flags != CGEventFlags.maskNonCoalesced
        if state.interactive == false {
          state.frontmostIndex = 0
          state.visibleMostIndex = 0
          subscriptions.passthrough.send()
        }
      }
  }

  func snapshot(refresh: Bool = false) -> WindowStoreSnapshot {
    if refresh {
      index(state.frontmostApplication)
    }
    return state.snapshot()
  }

  // MARK: - Private methods

  private func getWindows() -> [WindowModel] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private func index(_ runningApplication: UserSpace.Application) {
    let windows = getWindows()
    self.windows = windows
    indexAllApplicationsInSpace(windows)
    indexStage(windows)
    indexFrontmost()
  }

  private func indexAllApplicationsInSpace(_ models: [WindowModel]) {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 48, height: 48)
    let windowModels: [WindowModel] = models
      .filter {
        $0.ownerName != "borders" &&
        $0.alpha > 0 &&
        $0.id > 0 &&
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        !excluded.contains($0.ownerName)
      }
      .sorted { lhs, rhs in
        lhs.rect.origin.y < rhs.rect.origin.y
      }
    state.visibleWindowsInSpace = windowModels
  }

  private func indexStage(_ models: [WindowModel]) {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 300, height: 200)
    let windowModels: [WindowModel] = models
      .filter {
        $0.ownerName != "borders" &&
        $0.id > 0 &&
        $0.alpha > 0 &&
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        !excluded.contains($0.ownerName)
      }

    state.visibleWindowsInStage = windowModels
  }

  private func indexFrontmost() {
    do {
      let forbiddenSubroles = [
        NSAccessibility.Subrole.systemDialog.rawValue,
        NSAccessibility.Subrole.dialog.rawValue
      ]
      state.frontmostApplicationWindows = try state.appAccessibilityElement.windows()
        .filter({
          $0.id > 0 &&
          ($0.size?.height ?? 0) > 20 &&
          !forbiddenSubroles.contains($0.subrole ?? "")
        })
    } catch { }
  }
}

fileprivate extension WindowStore.State {
  func snapshot() -> WindowStoreSnapshot {
    WindowStoreSnapshot(
      frontmostApplicationWindows: frontmostApplicationWindows,
      visibleWindowsInStage: visibleWindowsInStage,
      visibleWindowsInSpace: visibleWindowsInSpace
    )
  }
}
