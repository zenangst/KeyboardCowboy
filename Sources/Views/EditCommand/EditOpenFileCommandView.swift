import Apps
import SwiftUI

struct EditOpenFileCommandView: View {
  @ObservedObject private var iO = Inject.observer
  @State private var applicationIdentifier: String = ""
  @State var command: OpenCommand { willSet { update(newValue) } }
  @State var filePath: String
  private let openPanelController: OpenPanelController
  private var installedApplications: [Application]
  private var noApplication: Application = Application.empty()
  private var update: (OpenCommand) -> Void

  init(command: OpenCommand,
       openPanelController: OpenPanelController,
       installedApplications: [Application],
       update: @escaping (OpenCommand) -> Void) {
    self._command = State(initialValue: command)
    self._filePath = State(initialValue: command.path)
    self.openPanelController = openPanelController
    var installedApplications = installedApplications
    installedApplications.insert(noApplication, at: 0)
    self.installedApplications = installedApplications
    self.update = update
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
      }
      .padding()
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
    .enableInjection()
  }
}

struct EditOpenFileCommandView_Previews: PreviewProvider {
  static var previews: some View {
    EditOpenFileCommandView(
      command: OpenCommand(path: ""),
      openPanelController: OpenPanelController(),
      installedApplications: contentStore.applicationStore.applications) { _ in}
  }
}
