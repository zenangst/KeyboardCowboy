import SwiftUI

struct FileMenu: View {
  @EnvironmentObject private var store: GroupStore
  @EnvironmentObject private var detail: ViewModelPublisher<DetailViewState>
  @EnvironmentObject private var info: ViewModelPublisher<DetailViewModel.Info>

  var onNewConfiguration: () -> Void
  var onNewGroup: () -> Void
  var onNewWorkflow: () -> Void

  var body: some View {
    Button(action: onNewConfiguration, label: { Text("New Configuration") })
    Button(action: onNewGroup, label: { Text("New Group") })
      .keyboardShortcut("n", modifiers: [.option, .command])
    Button(action: onNewWorkflow, label: { Text("New Workflow") })
      .keyboardShortcut("n", modifiers: [.command])
      .disabled(store.groups.isEmpty)
    NewCommandMenu {
      Text("New Command")
    }
    .disabled(!newCommandIsEnabled())
  }

  private func newCommandIsEnabled() -> Bool {
    switch detail.data {
    case .single: true
    default: false
    }
  }
}
