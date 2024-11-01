import SwiftUI
import Bonzai

struct WorkflowCommandEmptyListView: View {
  @EnvironmentObject var openWindow: WindowOpener
  private let namespace: Namespace.ID
  private let workflowId: String
  private let isPrimary: Binding<Bool>
  private let onAction: (SingleDetailView.Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       workflowId: String,
       isPrimary: Binding<Bool>,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.focus = focus
    self.isPrimary = isPrimary
    self.workflowId = workflowId
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
    VStack {
      FocusableButton(
        focus,
        identity: .detail(.addCommand),
        variant: .zen(.init(color: .systemGreen,
                            focusEffect: .constant(true),
                            grayscaleEffect: .readonly(!isPrimary.wrappedValue),
                            hoverEffect: .readonly(!isPrimary.wrappedValue))),
        action: {
          openWindow.openNewCommandWindow(.newCommand(workflowId: workflowId))
        }
      )
         {
        HStack {
          Image(systemName: "plus.app")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
          Divider()
            .opacity(0.5)

          Text("Add Command")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
      }
         .fixedSize()
         .matchedGeometryEffect(id: "add-command-button", in: namespace, properties: .position)
    }
    .padding()
    .dropDestination(CommandListDropItem.self, color: .accentColor, onDrop: { items, location in
      var urls = [URL]()
      for item in items {
        switch item {
        case .command: break
        case .url(let url):
          urls.append(url)
        }
      }

      if !urls.isEmpty {
        onAction(.dropUrls(workflowId: workflowId, urls: urls))
      }

      return true
    })
    .frame(maxWidth: .infinity, minHeight: 250, maxHeight: .infinity)
    .matchedGeometryEffect(id: "command-list", in: namespace)
  }
}

struct WorkflowCommandEmptyListView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  @Namespace static var namespace
  static var previews: some View {
    WorkflowCommandEmptyListView(
      $focus,
      namespace: namespace,
      workflowId: UUID().uuidString,
      isPrimary: .constant(true)
    ) { _ in }
      .designTime()
  }
}
