import AppKit
import Bonzai
import SwiftUI

@MainActor
final class GroupWindow: NSObject, NSWindowDelegate {
  enum Context: Identifiable, Hashable, Codable {
    var id: String {
      switch self {
      case .add(let group):
        return group.id
      case .edit(let group):
        return group.id
      }
    }
    case add(WorkflowGroup)
    case edit(WorkflowGroup)
  }

  private var window: NSWindow?

  private let context: Context
  private let applicationStore: ApplicationStore
  private let configurationPublisher: ConfigurationPublisher
  private let contentPublisher: ContentPublisher
  private let contentCoordinator: ContentCoordinator
  private let sidebarCoordinator: SidebarCoordinator

  init(context: Context, applicationStore: ApplicationStore,
       configurationPublisher: ConfigurationPublisher, contentPublisher: ContentPublisher,
       contentCoordinator: ContentCoordinator, sidebarCoordinator: SidebarCoordinator) {
    self.context = context
    self.applicationStore = applicationStore
    self.configurationPublisher = configurationPublisher
    self.contentPublisher = contentPublisher
    self.contentCoordinator = contentCoordinator
    self.sidebarCoordinator = sidebarCoordinator
  }

  func open(_ context: Context) {
    let content = EditWorfklowGroupView(applicationStore: applicationStore, group: resolve(context)) { [weak self] action in
      guard let self else { return }
      switch action {
      case .cancel:
        self.window?.close()
      case .ok(let updateGroup):
        switch context {
        case .add:
          sidebarCoordinator.handle(.add(updateGroup))
          contentCoordinator.handle(.add(updateGroup))
        case .edit:
          sidebarCoordinator.handle(.edit(updateGroup))
          contentCoordinator.handle(.edit(updateGroup))
        }
        self.window?.close()
      }
    }
      .environmentObject(configurationPublisher)

    let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .resizable, .titled, .fullSizeContentView]
    let window = ZenSwiftUIWindow(
      styleMask: styleMask,
      content: content
    )
    let size = window.hostingController.sizeThatFits(in: .zero)
    window.setFrame(NSRect(origin: .zero, size: size), display: false)

    window.animationBehavior = .documentWindow
    window.hostingController.view.frame.size = size
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.delegate = self
    window.makeKeyAndOrderFront(nil)
    window.center()

    self.window = window
  }

  func windowWillClose(_ notification: Notification) {
    window = nil
  }

  private func resolve(_ context: Context) -> WorkflowGroup {
    switch context {
    case .add(let group):  group
    case .edit(let group): group
    }
  }
}
