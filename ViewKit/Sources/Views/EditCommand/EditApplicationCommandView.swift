import SwiftUI
import ModelKit

public enum OpenPanelAction {
  case selectFile(type: String?, handler: (String) -> Void)
  case selectFolder(handler: (String) -> Void)
}

struct EditApplicationCommandView: View {
  @State private var selection: Int = 0
  @Binding var command: ApplicationCommand
  var installedApplications: [Application]

  init(command: Binding<ApplicationCommand>,
       installedApplications: [Application]) {
    self._command = command
    self.installedApplications = installedApplications
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Open application").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        Picker("Application: ", selection: Binding(get: {
          selection
        }, set: {
          selection = $0
          command = ApplicationCommand(id: command.id, application: installedApplications[$0])
        })) {
          ForEach(0..<installedApplications.count) { index in
            Text(installedApplications[index].bundleName).tag(index)
          }
        }
      }.onAppear {
        if let index = installedApplications.firstIndex(where: { command.application.bundleIdentifier == $0.bundleIdentifier }) {
          selection = index
        } else if !installedApplications.isEmpty {
          command = .init(id: command.id, application: installedApplications.first!)
        }
      }.padding()
    }
  }
}

struct EditApplicationCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    let models = ModelFactory().installedApplications()
    return EditApplicationCommandView(
      command: .constant(ApplicationCommand(application: .finder())),
      installedApplications: models)
  }
}
