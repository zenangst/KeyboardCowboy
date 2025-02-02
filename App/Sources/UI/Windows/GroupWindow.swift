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
  private let contentPublisher: GroupDetailPublisher
  private let contentCoordinator: GroupCoordinator
  private let sidebarCoordinator: SidebarCoordinator

  init(context: Context, applicationStore: ApplicationStore,
       configurationPublisher: ConfigurationPublisher, contentPublisher: GroupDetailPublisher,
       contentCoordinator: GroupCoordinator, sidebarCoordinator: SidebarCoordinator) {
    self.context = context
    self.applicationStore = applicationStore
    self.configurationPublisher = configurationPublisher
    self.contentPublisher = contentPublisher
    self.contentCoordinator = contentCoordinator
    self.sidebarCoordinator = sidebarCoordinator
  }

  func open(_ context: Context) {
    let windowManager = WindowManager()
    let content = EditWorfklowGroupView(applicationStore: applicationStore, group: resolve(context)) { [windowManager, sidebarCoordinator, contentCoordinator] action in
      switch action {
      case .cancel:
        windowManager.window?.close()
      case .ok(let updateGroup):
        switch context {
        case .add:
          sidebarCoordinator.handle(.add(updateGroup))
          contentCoordinator.handle(.add(updateGroup))
          sidebarCoordinator.handle(.selectGroups([updateGroup.id]))
          contentCoordinator.handle(.selectGroups([updateGroup.id]))
        case .edit:
          sidebarCoordinator.handle(.edit(updateGroup))
          contentCoordinator.handle(.edit(updateGroup))
        }
        windowManager.window?.close()
      }
    }
      .environmentObject(configurationPublisher)
      .environmentObject(windowManager)

    let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .resizable, .titled, .fullSizeContentView]
    let window = ZenSwiftUIWindow(
      styleMask: styleMask,
      content: content
    )
    windowManager.window = window
    let size = window.sizeThatFits(in: .zero)
    window.setFrame(NSRect(origin: .zero, size: size), display: false)

    window.animationBehavior = .documentWindow
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.delegate = self
    window.standardWindowButton(.closeButton)?.isBordered = true
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
