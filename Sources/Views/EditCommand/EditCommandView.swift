import Apps
import SwiftUI

struct EditCommandView: View {
  @ObserveInjection var inject
  @ObservedObject var applicationStore: ApplicationStore
  @ObservedObject var openPanelController: OpenPanelController
  let imageSize = CGSize(width: 32, height: 32)
  let saveAction: (Command) -> Void
  let cancelAction: () -> Void
  @State var selection: Command?
  @State var command: Command
  private let commands: [Command]

  init(applicationStore: ApplicationStore,
       openPanelController: OpenPanelController,
       saveAction: @escaping (Command) -> Void,
       cancelAction: @escaping () -> Void,
       selection: Command?,
       command: Command) {
    self.applicationStore = applicationStore
    self.openPanelController = openPanelController
    self.saveAction = saveAction
    self.cancelAction = cancelAction
    self.commands = ModelFactory().commands(id: command.id)
    _command = .init(initialValue: command)
    _selection = .init(initialValue: command)
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 0) {
        EditCommandListView(
          selection: $selection,
          command: $command,
          commands: commands)
        .frame(width: 250)
        VStack {
         EditCommandDetailView(
          applicationStore: applicationStore,
          openPanelController: openPanelController,
          selection: $selection,
          command: $command)
            .frame(width: 450)
          Spacer()
          Divider()
          HStack {
            Spacer()
            Button(action: cancelAction,
                   label: { Text("Cancel").frame(minWidth: 60) })
            .keyboardShortcut(.cancelAction)
            Button(action: {
              saveAction(command)
            },
                   label: { Text("OK").frame(minWidth: 60) })
              .keyboardShortcut(.defaultAction)
          }
            .padding(8)
            .frame(alignment: .bottom)
        }
      }.background(Color(.windowBackgroundColor))
    }
    .frame(height: 400)
    .enableInjection()
  }
}

struct EditCommandView_Previews: PreviewProvider {
  static var previews: some View {
    EditCommandView(applicationStore: contentStore.applicationStore,
                    openPanelController: OpenPanelController(),
                    saveAction: { _ in },
                    cancelAction: {},
                    selection: nil,
                    command: Command.application(ApplicationCommand(application: Application.finder())))
  }
}
