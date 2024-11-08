import Bonzai
import Inject
import SwiftUI

struct WorkflowCommandEmptyListView: View {
  @ObserveInjection var inject
  @EnvironmentObject var applicationStore: ApplicationStore
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject var openWindow: WindowOpener
  private let namespace: Namespace.ID
  private let workflowId: String
  private let isPrimary: Binding<Bool>
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       workflowId: String,
       isPrimary: Binding<Bool>) {
    self.focus = focus
    self.isPrimary = isPrimary
    self.workflowId = workflowId
    self.namespace = namespace
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
           HStack(spacing: 4) {
             Text("⌘N")
               .font(Font.system(size: 8, weight: .semibold))
               .padding(.horizontal, 4)
               .padding(.vertical, 2)
               .background(
                RoundedRectangle(cornerRadius: 4)
                  .stroke(Color(nsColor: .systemGreen.blended(withFraction: 0.3, of: .black)!), lineWidth: 1)
                  .opacity(0.5)
               )

             Divider()
               .opacity(0.5)

             Text("Add Command")
           }
           .padding(.vertical, 4)
           .padding(.horizontal, 6)
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
        updater.modifyWorkflow(using: transaction) { workflow in
          let commands = DropCommandsController.generateCommands(from: urls, applications: applicationStore.applications)
          workflow.commands.append(contentsOf: commands)
        }
      }

      return true
    })
    .frame(maxWidth: .infinity, minHeight: 250, maxHeight: .infinity)
    .matchedGeometryEffect(id: "command-list", in: namespace)
    .enableInjection()
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
    ).designTime()
  }
}
