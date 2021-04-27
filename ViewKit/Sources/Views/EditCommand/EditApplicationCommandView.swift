import SwiftUI
import ModelKit

public enum OpenPanelAction {
  case selectFile(type: String?, handler: (String) -> Void)
  case selectFolder(handler: (String) -> Void)
}

struct EditApplicationCommandView: View {
  @State private var selection: Int = 0
  @State var command: ApplicationCommand {
    willSet {
      update(newValue)
    }
  }
  var installedApplications: [Application]
  var update: (ApplicationCommand) -> Void

  init(command: ApplicationCommand,
       installedApplications: [Application],
       update: @escaping (ApplicationCommand) -> Void = { _ in }) {
    self._command = State(initialValue: command)
    self.installedApplications = installedApplications
    self.update = update
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Application").font(.title)
        Spacer()
      }.padding()
      Divider()
      HelperView(text: "Pick the application that you want to launch/activate or close", {
        Group {
          VStack {
            HStack {
              Picker("", selection: Binding<ApplicationCommand.Action>(
                get: { command.action },
                set: { command.action = $0 }
              )) {
                ForEach(ApplicationCommand.Action.allCases) { action in
                  Text(action.displayValue).tag(action)
                }
              }.frame(maxWidth: 80)

              Picker("", selection: Binding<Int>(get: {
                selection
              }, set: {
                selection = $0
                command.application = installedApplications[$0]
              })) {
                ForEach(0..<installedApplications.count, id: \.self) { index in
                  Text(installedApplications[index].displayName).tag(index)
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
      })
    }.onAppear {
      if let index = installedApplications
          .firstIndex(where: { command.application.bundleIdentifier == $0.bundleIdentifier }) {
        selection = index
      } else if !installedApplications.isEmpty {
        selection = 0
        command.application = installedApplications.first!
      }
    }
  }
}

struct EditApplicationCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditApplicationCommandView(
      command: ApplicationCommand(application: .finder()),
      installedApplications: ModelFactory().installedApplications())
  }
}
