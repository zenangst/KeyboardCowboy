import SwiftUI
import ModelKit

public enum OpenPanelAction {
  case selectFile(type: String?, handler: (String) -> Void)
  case selectFolder(handler: (String) -> Void)
}

struct EditApplicationCommandView: View {
  @State private var selection: Int = 0
  @State private var modifiers: [ApplicationCommand.Modifier]
  @Binding var command: ApplicationCommand
  var installedApplications: [Application]

  init(command: Binding<ApplicationCommand>, installedApplications: [Application]) {
    self._command = command
    self._modifiers = State(initialValue: command.modifiers.wrappedValue)
    self.installedApplications = installedApplications
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
              Picker("", selection: Binding(get: {
                command.action
              }, set: { newAction in
                command = ApplicationCommand(id: command.id,
                                             action: newAction,
                                             application: command.application)
              })) {
                ForEach(ApplicationCommand.Action.allCases) { action in
                  Text(action.displayValue).tag(action)
                }
              }.frame(maxWidth: 80)
              Picker("", selection: Binding(get: {
                selection
              }, set: {
                selection = $0
                command = ApplicationCommand(id: command.id,
                                             action: command.action,
                                             application: installedApplications[$0])
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
                    modifiers.contains(modifier)
                  }, set: { _ in
                    if let index = modifiers.firstIndex(of: modifier) {
                      modifiers.remove(at: index)
                    } else {
                      modifiers.append(modifier)
                    }
                    command.modifiers = modifiers
                  })).tag(modifier)
                }
                Spacer()
              }
            }
          }.padding()
        }
      })
    }.onAppear {
      if let index = installedApplications
          .firstIndex(where: { command.application.bundleIdentifier == $0.bundleIdentifier }) {
        selection = index
      } else if !installedApplications.isEmpty {
        command = .init(id: command.id, application: installedApplications.first!)
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
      command: .constant(ApplicationCommand(application: .finder())),
      installedApplications: ModelFactory().installedApplications())
  }
}
