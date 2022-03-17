import Apps
import SwiftUI

public enum OpenPanelAction {
  case selectFile(type: String?, handler: (String) -> Void)
  case selectFolder(handler: (String) -> Void)
}

struct EditApplicationCommandView: View {
  @State var command: ApplicationCommand {
    willSet { update(newValue) }
  }
  var applicationStore: ApplicationStore
  var update: (ApplicationCommand) -> Void

  init(command: ApplicationCommand,
       applicationStore: ApplicationStore,
       update: @escaping (ApplicationCommand) -> Void = { _ in }) {
    self._command = State(initialValue: command)
    self.applicationStore = applicationStore
    self.update = update
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Application").font(.title)
        Spacer()
      }.padding()
      Divider()
      Group {
        VStack {
          HStack {
            Picker("Action:", selection: $command.action) {
              ForEach(ApplicationCommand.Action.allCases) { action in
                Text(action.displayValue)
                  .tag(action)
              }
            }
            .onChange(of: command.action, perform: { action in command.action = action })
            .frame(maxWidth: 120)

            Spacer()
            ApplicationPickerView(applicationStore, title: "", selection: Binding<Application?>(
              get: { command.application }, set: { application in
                guard let application = application else { return }
                command.application = application
              }
            ))
          }
          .offset(x: -8, y: 0)

          if $command.action.wrappedValue == .open {
            Divider()
            TogglesView(ApplicationCommand.Modifier.allCases,
                        enabled: $command.modifiers, id: \.id)
            .onChange(of: command.modifiers, perform: { modifiers in
              command.modifiers = modifiers
            })
            .font(Font.caption2)
          }
        }.padding()
      }
    }
  }
}

struct EditApplicationCommandView_Previews: PreviewProvider {
  static var previews: some View {
    EditApplicationCommandView(command: .init(application: Application.finder()),
                               applicationStore: applicationStore)
  }
}
