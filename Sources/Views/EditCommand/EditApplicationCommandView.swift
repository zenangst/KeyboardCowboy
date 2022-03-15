import Apps
import SwiftUI

public enum OpenPanelAction {
  case selectFile(type: String?, handler: (String) -> Void)
  case selectFolder(handler: (String) -> Void)
}

struct EditApplicationCommandView: View {
  @State private var selection: String
  @State var command: ApplicationCommand {
    willSet { update(newValue) }
  }
  var installedApplications: [Application]
  var update: (ApplicationCommand) -> Void

  init(command: ApplicationCommand,
       installedApplications: [Application],
       update: @escaping (ApplicationCommand) -> Void = { _ in }) {
    self._command = State(initialValue: command)
    self.installedApplications = installedApplications
    self.update = update

    if let match = installedApplications
        .first(where: { command.application.bundleIdentifier == $0.bundleIdentifier }) {
      _selection = .init(initialValue: match.bundleIdentifier)
    } else if let firstApplication = installedApplications.first {
      _selection = .init(initialValue: firstApplication.bundleIdentifier)
    } else {
      _selection = .init(initialValue: "")
    }
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
            Picker("", selection: $command.action) {
              ForEach(ApplicationCommand.Action.allCases) { action in
                Text(action.displayValue)
                  .tag(action)
              }
            }
            .frame(maxWidth: 80)

            Picker("", selection: $selection) {
              ForEach(installedApplications, id: \.bundleIdentifier) { application in
                Text(application.displayName)
                  .id(application.bundleIdentifier)
              }
            }
          }
          .offset(x: -8, y: 0)

          if $command.action.wrappedValue == .open {
            Divider()

            HStack {
              ForEach(ApplicationCommand.Modifier.allCases) { modifier in
                Toggle(modifier.displayValue, isOn: Binding<Bool>(get: {
                  command.modifiers.contains(modifier)
                }, set: { _ in
                  var modifiers = command.modifiers
                  if let index = command.modifiers.firstIndex(of: modifier) {
                    modifiers.remove(at: index)
                  } else {
                    modifiers.append(modifier)
                  }
                  command.modifiers = modifiers
                })).tag(modifier)
              }
              Spacer()
            }.font(Font.caption2)
          }
        }.padding()
      }
    }
  }
}

struct EditApplicationCommandView_Previews: PreviewProvider {
  static var previews: some View {
    EditApplicationCommandView(command: .init(application: Application.finder()),
                               installedApplications: [])
  }
}
