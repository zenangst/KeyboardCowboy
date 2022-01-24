import Foundation

final class WorkflowGroupStore: ObservableObject {
  @Published var groups = [WorkflowGroup]()

  init(_ groups: [WorkflowGroup] = []) {
    _groups = .init(initialValue: groups)
  }
}
