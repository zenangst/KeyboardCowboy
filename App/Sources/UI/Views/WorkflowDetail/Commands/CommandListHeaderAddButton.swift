import SwiftUI
import Inject
import Bonzai

struct CommandListHeaderAddButton: View {
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject var openWindow: WindowOpener
  private let namespace: Namespace.ID

  init(_ namespace: Namespace.ID) {
    self.namespace = namespace
  }

  var body: some View {
    NewCommandButton {
      Image(systemName: "plus")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 20, height: 20)
        .layoutPriority(-1)
      Text(" ")
    }
    .fixedSize()
    .help("Add Command")
    .matchedGeometryEffect(id: "add-command-button", in: namespace, properties: .position)
    .enableInjection()
  }
}

#Preview {
  @Namespace var namespace
  return CommandListHeaderAddButton(namespace)
    .designTime()
    .padding()
}
