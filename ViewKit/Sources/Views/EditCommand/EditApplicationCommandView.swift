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

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Open application").font(.title)
        Spacer()
      }.padding()
      Divider()
      HelperView(text: "Pick the application that you want to launch/activate", contentView: Group {
        VStack {
          Picker("Application: ", selection: Binding(get: {
            selection
          }, set: {
            selection = $0
            command = ApplicationCommand(id: command.id, application: installedApplications[$0])
          })) {
            ForEach(0..<installedApplications.count, id: \.self) { index in
              Text(installedApplications[index].displayName).tag(index)
            }
          }
        }.padding()
      }.erase())
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
    let models = ModelFactory().installedApplications()
    return EditApplicationCommandView(
      command: .constant(ApplicationCommand(application: .finder())),
      installedApplications: models)
  }
}
