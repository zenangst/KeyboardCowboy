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

  init(_ contentStore: ContentStore) {
    self.applicationStore = contentStore.applicationStore
    self.groupStore = contentStore.groupStore
  }

  var body: some Scene {
    WindowGroup(for: Context.self) { $context in
      ScrollView {
        EditWorfklowGroupView(applicationStore: applicationStore, group: resolve(context)) { action in
          switch action {
          case .cancel:
            break
          case .ok(let group):
            switch context! {
            case .add:
              groupStore.add(group)
            case .edit:
              groupStore.updateGroups([group])
            }
          }
          KeyboardCowboy.app.keyWindow?.close()
        }
      }
      .frame(minWidth: 520, minHeight: 280, idealHeight: 280)
    }
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
