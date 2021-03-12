import SwiftUI
import ModelKit

struct EditOpenFileCommandView: View {
  @State private var applicationIdentifier: String = ""
  @Binding var command: OpenCommand
  @State var filePath: String
  private let openPanelController: OpenPanelController
  private var installedApplications: [Application]
  private var noApplication: Application = Application.empty()

  init(command: Binding<OpenCommand>,
       openPanelController: OpenPanelController,
       installedApplications: [Application]) {
    _command = command
    _filePath = State(initialValue: command.wrappedValue.path)
    self.openPanelController = openPanelController

    var installedApplications = installedApplications
    installedApplications.insert(noApplication, at: 0)
    self.installedApplications = installedApplications
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Open a file").font(.title)
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
                            application: command.application,
                            path: command.path)
          }))
        }
        HStack {
          Text("Path:").frame(width: 80, alignment: .trailing)
          TextField("file://", text: Binding<String>(get: {
            filePath
          }, set: {
            filePath = $0
            command = .init(id: command.id,
                            name: command.name,
                            application: command.application,
                            path: $0)
          }))
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: nil, handler: {
              let newCommand = OpenCommand(id: command.id, path: $0)
              command = newCommand
              filePath = newCommand.path
            }))
          })
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
    }.onAppear {
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

struct EditOpenFileCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditOpenFileCommandView(
      command: .constant(OpenCommand(path: "")),
      openPanelController: OpenPanelPreviewController().erase(),
      installedApplications: ModelFactory().installedApplications())
  }
}
