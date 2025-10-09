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

  init(frontmostApplicationWindows: [WindowAccessibilityElement], visibleWindowsInStage: [WindowModel], visibleWindowsInSpace: [WindowModel]) {
    self.frontmostApplicationWindows = frontmostApplicationWindows
    self.visibleWindowsInStage = visibleWindowsInStage
    self.visibleWindowsInSpace = visibleWindowsInSpace
  }
}

final class WindowStore: @unchecked Sendable {
  final class Subscriptions {
    var flagsChange: AnyCancellable?
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

    @MainActor init() {
      let pid = UserSpace.Application.current.ref.processIdentifier
      appAccessibilityElement = AppAccessibilityElement(pid)
      frontmostApplication = .current
    }
  }

  @MainActor static let shared: WindowStore = .init()

  @Published private(set) var windows: [WindowModel] = []

  let state: State

  private let subscriptions: Subscriptions = .init()

  @MainActor private init() {
    state = State()
  }

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    subscriptions.frontmostApplication = publisher
      .compactMap(\.self)
      .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
      .sink { [weak self, state] application in
        guard let self else { return }

        let pid = application.ref.processIdentifier
        state.appAccessibilityElement = AppAccessibilityElement(pid)
        state.frontmostApplication = application
        index()
      }
  }

  func snapshot(refresh: Bool = false) -> WindowStoreSnapshot {
    if refresh {
      index()
    }
    return state.snapshot()
  }

  func allApplicationsInSpace(_ models: [WindowModel], onScreen: Bool, sorted: Bool = true) -> [WindowModel] {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 32, height: 32)
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

  func getWindows(onScreen: Bool = true) -> [WindowModel] {
    let options: CGWindowListOption = onScreen
      ? [.optionOnScreenOnly, .excludeDesktopElements]
      : [.excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  func index() {
    let windows = getWindows()
    self.windows = windows
    state.visibleWindowsInSpace = allApplicationsInSpace(windows, onScreen: true)
    state.visibleWindowsInStage = indexStage(windows)
    indexFrontMost()
  }

  func indexFrontMost() {
    do {
      let forbiddenSubroles = [
        NSAccessibility.Subrole.dialog.rawValue,
        NSAccessibility.Subrole.floatingWindow.rawValue,
        NSAccessibility.Subrole.systemDialog.rawValue,
        NSAccessibility.Subrole.systemFloatingWindow.rawValue,
      ]
      state.frontmostApplicationWindows = try state.appAccessibilityElement
        .windows { window in
          window.id > 0 &&
            (window.size?.height ?? 0) > 20 &&
            !forbiddenSubroles.contains(window.subrole ?? "")
        }
    } catch {}
  }
}

private extension WindowStore.State {
  func snapshot() -> WindowStoreSnapshot {
    WindowStoreSnapshot(
      frontmostApplicationWindows: frontmostApplicationWindows.filter { $0.id > 0 },
      visibleWindowsInStage: visibleWindowsInStage.filter { $0.id > 0 },
      visibleWindowsInSpace: visibleWindowsInSpace.filter { $0.id > 0 },
    )
  }
}
