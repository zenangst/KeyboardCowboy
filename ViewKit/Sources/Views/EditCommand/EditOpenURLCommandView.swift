import SwiftUI
import ModelKit

struct EditOpenURLCommandView: View {
  @State private var applicationIdentifier: String = ""
  @State var url: String = ""
  @Binding var command: OpenCommand
  var installedApplications: [Application]
  private var noApplication: Application = Application.empty()

  init(command: Binding<OpenCommand>, installedApplications: [Application]) {
    _command = command
    var installedApplications = installedApplications
    installedApplications.insert(noApplication, at: 0)
    self.installedApplications = installedApplications
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Open URL").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        HStack {
          Text("Name:").frame(width: 80, alignment: .trailing)
          TextField(command.name, text: Binding(get: {
            command.name
          }, set: {
            command = .init(id: command.id,
                            name: $0,
                            application: command.application, path: command.path)
          }))
        }
        HStack {
          Text("URL:").frame(width: 80, alignment: .trailing)
          TextField("http://", text: Binding(get: {
            command.path
          }, set: {
            command = .init(id: command.id,
                            name: command.name,
                            application: command.application,
                            path: $0)
          }))
        }
        HStack(spacing: 0) {
          Text("Application:").frame(width: 80, alignment: .trailing)
          Picker("", selection: Binding(get: {
            applicationIdentifier
          }, set: {
            applicationIdentifier = $0

            var application: Application? = installedApplications
              .first(where: { $0.id == applicationIdentifier })
            if application == noApplication {
              application = nil
            }

            command = .init(id: command.id, name: command.name,
                            application: application, path: command.path)
          })) {
            ForEach(installedApplications, id: \.id) { element in
              Text(element.displayName)
                .tag(element.id)
            }
          }
        }
      }.padding()
    }
    .onAppear {
      if let application = installedApplications
          .first(where: { command.application?.bundleIdentifier == $0.bundleIdentifier }) {
        applicationIdentifier = application.id
      } else if !installedApplications.isEmpty {
        command = .init(id: command.id,
                        application: installedApplications.first!,
                        path: "")
      }
    }
  }
}

struct EditOpenURLCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditOpenURLCommandView(
      command: .constant(OpenCommand.empty()),
      installedApplications: ModelFactory().installedApplications()
    )
  }
}
