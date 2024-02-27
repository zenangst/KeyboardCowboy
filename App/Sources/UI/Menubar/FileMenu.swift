import SwiftUI

struct FileMenu: View {
  @EnvironmentObject private var store: GroupStore
  @EnvironmentObject private var detail: ViewModelPublisher<DetailViewState>
  @EnvironmentObject private var info: ViewModelPublisher<DetailViewModel.Info>

  var onNewConfiguration: () -> Void
  var onNewGroup: () -> Void
  var onNewWorkflow: () -> Void
  var onNewCommand: (DetailViewModel.Info.ID) -> Void

  var body: some View {
    Button(action: onNewConfiguration, label: { Text("New Configuration") })
    Button(action: onNewGroup, label: { Text("New Group") })
      .keyboardShortcut("n", modifiers: [.control, .option, .command])
    Button(action: onNewWorkflow, label: { Text("New Workflow") })
      .keyboardShortcut("n", modifiers: [.option, .command])
      .disabled(store.groups.isEmpty)
    Button(action: {
      onNewCommand(info.data.id)
    }, label: { Text("New Command") })
      .keyboardShortcut("n", modifiers: [.command])
      .disabled(!newCommandIsEnabled())
  }

  private func newCommandIsEnabled() -> Bool {
    switch detail.data {
    case .single: true
    default: false
    }
  }
}
