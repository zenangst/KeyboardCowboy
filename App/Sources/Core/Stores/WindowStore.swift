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
        self.indexFrontmost()
      }
  }

  func snapshot(refresh: Bool = false) -> WindowStoreSnapshot {
    if refresh {
      index(state.frontmostApplication)
    }
    return state.snapshot()
  }

  func allApplicationsInSpace(_ models: [WindowModel], onScreen: Bool, sorted: Bool = true) -> [WindowModel] {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 48, height: 48)
    let windowModels: [WindowModel] = models
      .filter {
        $0.ownerName != "borders" &&
        $0.alpha > 0 &&
        $0.id > 0 &&
        (onScreen ? $0.isOnScreen : true) &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        !excluded.contains($0.ownerName)
      }

    if sorted {
      return windowModels.sorted { lhs, rhs in
        lhs.rect.origin.y < rhs.rect.origin.y
      }
    }

    return windowModels
  }

  func indexStage(_ models: [WindowModel]) -> [WindowModel] {
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
    return windowModels
  }

  func getWindows(onScreen: Bool =  true) -> [WindowModel] {
    let options: CGWindowListOption = onScreen
    ? [.optionOnScreenOnly, .excludeDesktopElements]
    : [.excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }
  
  func index(_ runningApplication: UserSpace.Application) {
    let windows = getWindows()
    self.windows = windows
    state.visibleWindowsInSpace = allApplicationsInSpace(windows, onScreen: true)
    state.visibleWindowsInStage = indexStage(windows)
    indexFrontmost()
  }

  func indexFrontmost() {
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
      frontmostApplicationWindows: frontmostApplicationWindows.filter({ $0.id > 0 }),
      visibleWindowsInStage: visibleWindowsInStage.filter({ $0.id > 0 }),
      visibleWindowsInSpace: visibleWindowsInSpace.filter({ $0.id > 0 })
    )
  }
}
