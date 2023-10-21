import SwiftUI

struct FileMenu: View {
  @EnvironmentObject private var store: GroupStore

  var onNewConfiguration: () -> Void
  var onNewGroup: () -> Void
  var onNewWorkflow: () -> Void

  var body: some View {
    Button(action: onNewConfiguration, label: { Text("New Configuration") })
    Button(action: onNewGroup, label: { Text("New Group") })
      .keyboardShortcut("n", modifiers: [.control, .option, .command])
    Button(action: onNewWorkflow, label: { Text("New Workflow") })
      .keyboardShortcut("n", modifiers: [.option, .command])
      .disabled(store.groups.isEmpty)
  }
}
