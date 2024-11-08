import SwiftUI
import Bonzai

struct CommandListHeaderAddButton: View {
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject var openWindow: WindowOpener
  private let namespace: Namespace.ID

  init(_ namespace: Namespace.ID) {
    self.namespace = namespace
  }

  var body: some View {
    Button(action: {
      openWindow.openNewCommandWindow(.newCommand(workflowId: transaction.workflowID))
    }) {
      HStack(spacing: 4) {
        Image(systemName: "plus.app")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 12, height: 12)
          .padding(2)
          .layoutPriority(-1)
      }
    }
    .help("Add Command")
    .buttonStyle(.zen(.init(color: .systemGreen, grayscaleEffect: .constant(true))))
    .matchedGeometryEffect(id: "add-command-button", in: namespace, properties: .position)
  }
}

#Preview {
  @Namespace var namespace
  return CommandListHeaderAddButton(namespace)
    .designTime()
    .padding()
}
