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
    var frontmostApplication: UserSpace.Application = .current
    var frontMostIndex: Int = 0
    var visibleMostIndex: Int = 0
    var interactive: Bool = false
    var frontMostApplicationWindows: [WindowAccessibilityElement] = .init()
    var visibleWindowsInStage: [WindowModel] = .init()
    var visibleWindowsInSpace: [WindowModel] = .init()
  }

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
        state.frontmostApplication = application
        state.frontMostIndex = 0
        self.indexFrontmost(application)
        if state.interactive == false {
          self.index(application)
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
    let options: CGWindowListOption = [.optionOnScreenOnly, .optionIncludingWindow, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private func index(_ runningApplication: UserSpace.Application) {
    let windowModels = getWindows()
    indexAllApplicationsInSpace(windowModels)
    indexStage(windowModels)
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

  private func indexFrontmost(_ frontMostApplication: UserSpace.Application) {
    let pid = state.frontmostApplication.ref.processIdentifier
    let element = AppAccessibilityElement(pid)
    do {
      state.frontMostApplicationWindows = try element.windows()
        .filter({
          $0.id > 0 &&
          ($0.frame?.size.height ?? 0) > 20
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
