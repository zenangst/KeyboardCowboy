import SwiftUI

@MainActor
struct EditWorkflowGroupWindow: Scene {
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

  private let applicationStore: ApplicationStore
  private let groupStore: GroupStore
  private let onSubmit: (Context) -> Void
  private let configurationPublisher: ConfigurationPublisher

  init(_ contentStore: ContentStore, 
       configurationPublisher: ConfigurationPublisher,
       onSubmit: @escaping (Context) -> Void) {
    self.applicationStore = contentStore.applicationStore
    self.configurationPublisher = configurationPublisher
    self.groupStore = contentStore.groupStore
    self.onSubmit = onSubmit
  }

  var body: some Scene {
    WindowGroup(for: Context.self) { $context in
      EditWorfklowGroupView(applicationStore: applicationStore, group: resolve(context)) { action in
        switch action {
        case .cancel:
          break
        case .ok(let updatedGroup):
          switch context! {
          case .add:
            onSubmit(.add(updatedGroup))
          case .edit:
            onSubmit(.edit(updatedGroup))
          }
        }
        KeyboardCowboy.keyWindow?.close()
        KeyboardCowboy.mainWindow?.makeKey()
      }
      .environmentObject(configurationPublisher)
    }
    .windowResizability(.contentMinSize)
  }

  private func resolve(_ context: Context?) -> WorkflowGroup {
    switch context {
    case .add(let group):
      return group
    case .edit(let group):
      return group
    case .none:
      fatalError("This shouldn't happen")
    }
  }
}
