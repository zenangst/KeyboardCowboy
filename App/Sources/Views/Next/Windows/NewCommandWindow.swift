import Apps
import Carbon
import SwiftUI

enum NewCommandPayload {
  case placeholder
  case application(application: Application, action: NewCommandApplicationView.ApplicationAction,
                   inBackground: Bool, hideWhenRunning: Bool, ifNotRunning: Bool)
  case url(targetUrl: URL, application: Application?)
  case open(path: String, application: Application?)
  case shortcut(name: String)
  case type(text: String)
}

struct NewCommandWindow: Scene {
  enum Context: Identifiable, Hashable, Codable {
    var id: String {
      switch self {
      case .newCommand(let workflowId):
        return workflowId
      }
    }

    case newCommand(workflowId: Workflow.ID)
  }

  private let onSave: (Workflow.ID, NewCommandPayload) -> Void
  private let contentStore: ContentStore

  init(contentStore: ContentStore, onSave: @escaping (Workflow.ID, NewCommandPayload) -> Void) {
    self.contentStore = contentStore
    self.onSave = onSave
  }

  var body: some Scene {
    WindowGroup(for: Context.self) { $context in
      switch context {
      case .newCommand(let workflowId):
        NewCommandView(
          workflowId: workflowId,
          onDismiss: {
            closeWindow()
          }, onSave: { payload in
            onSave(workflowId, payload)
            closeWindow()
          })
        .environmentObject(contentStore.shortcutStore)
        .environmentObject(contentStore.applicationStore)
        .environmentObject(OpenPanelController())
        .ignoresSafeArea(edges: .all)
      case .none:
        EmptyView()
      }
    }
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)
    .defaultPosition(.topTrailing)
  }

  private func closeWindow() {
    KeyboardCowboy.keyWindow?.close()
    KeyboardCowboy.mainWindow?.makeKey()
  }
}

