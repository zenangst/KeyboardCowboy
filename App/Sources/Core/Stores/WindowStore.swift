import Apps
import AXEssibility
import Cocoa
import Combine
import Dock
import Foundation
import MachPort
import Windows

struct WindowStoreSnapshot: @unchecked Sendable {
  let frontMostApplicationWindows: [WindowAccessibilityElement]
  let visibleWindowsInStage: [WindowModel]
  let visibleWindowsInSpace: [WindowModel]

  init(frontMostApplicationWindows: [WindowAccessibilityElement],
       visibleWindowsInStage: [WindowModel],
       visibleWindowsInSpace: [WindowModel]) {
    self.frontMostApplicationWindows = frontMostApplicationWindows
    self.visibleWindowsInStage = visibleWindowsInStage
    self.visibleWindowsInSpace = visibleWindowsInSpace
  }
}

final class WindowStore {
  final class Subscriptions {
    var flagsChange: AnyCancellable?
    var passthrough = PassthroughSubject<Void, Never>()
    var subject: AnyCancellable?
    var frontMostApplication: AnyCancellable?
  }

  final class State {
    var appAccessibilityElement: AppAccessibilityElement
    var frontmostApplication: UserSpace.Application = .current
    var frontMostIndex: Int = 0
    var visibleMostIndex: Int = 0
    var interactive: Bool = false
    var frontMostApplicationWindows: [WindowAccessibilityElement] = .init()
    var visibleWindowsInStage: [WindowModel] = .init()
    var visibleWindowsInSpace: [WindowModel] = .init()

    init() {
      let pid = UserSpace.Application.current.ref.processIdentifier
      self.appAccessibilityElement = AppAccessibilityElement(pid)
    }
  }

  @Published private(set) var windows: [WindowModel] = []

  private let subscriptions: Subscriptions = .init()
  let state: State = .init()

  static let shared: WindowStore = .init()

  private init() { }

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    subscriptions.frontMostApplication = publisher
      .compactMap { $0 }
      .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
      .sink { [weak self, state] application in
        guard let self else { return }

        let pid = application.ref.processIdentifier
        state.appAccessibilityElement = AppAccessibilityElement(pid)
        state.frontmostApplication = application
        state.frontMostIndex = 0
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
          state.frontMostIndex = 0
          state.visibleMostIndex = 0
          subscriptions.passthrough.send()
        }
      }
  }

  func snapshot() -> WindowStoreSnapshot {
    state.snapshot()
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
    state.visibleWindowsInSpace = windowModels
  }

  private func indexStage(_ models: [WindowModel]) {
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

    state.visibleWindowsInStage = windowModels
  }

  private func indexFrontmost() {
    do {
      state.frontMostApplicationWindows = try state.appAccessibilityElement.windows()
        .filter({
          $0.id > 0 &&
          ($0.size?.height ?? 0) > 20
        })
    } catch { }
  }
}

fileprivate extension WindowStore.State {
  func snapshot() -> WindowStoreSnapshot {
    WindowStoreSnapshot(
      frontMostApplicationWindows: frontMostApplicationWindows,
      visibleWindowsInStage: visibleWindowsInStage,
      visibleWindowsInSpace: visibleWindowsInSpace
    )
  }
}
