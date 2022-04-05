import SwiftUI

struct EditShellScriptView: View {
  @ObservedObject private var iO = Inject.observer
  enum Kind: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case source
    case file

    var displayValue: String {
      switch self {
      case .source:
        return "Source"
      case .file:
        return "File"
      }
    }
  }
  @State var command: ScriptCommand {
    willSet { update(newValue) }
  }
  @State var filePath: String
  @State var source: String
  @State var kind: Kind

  let openPanelController: OpenPanelController
  var update: (ScriptCommand) -> Void

  init(command: ScriptCommand,
       openPanelController: OpenPanelController,
       update: @escaping (ScriptCommand) -> Void) {
    self._command = State(initialValue: command)
    _filePath = State(initialValue: command.path)
    self.openPanelController = openPanelController
    self.update = update

    switch command {
    case .appleScript:
      _kind = .init(initialValue: .file)
      _source = State(initialValue: command.source)
    case .shell(_, _, _, let source):
      switch source {
      case .path:
        _kind = .init(initialValue: .file)
        _source = State(initialValue: command.source)
      case .inline(let string):
        _kind = .init(initialValue: .source)
        _source = .init(initialValue: string)
      }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Shellscript").font(.title)
        Spacer()
      }.padding()
      Divider()

      Picker("", selection: $kind) {
        ForEach(Kind.allCases, id: \.rawValue, content: { kind in
          Text(kind.displayValue)
            .tag(kind)
        })
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding()

      switch kind {
      case .file:
       filePicker
      case .source:
        ScriptEditorView(text: Binding<String> {
          command.source
        } set: { input in
          command = .shell(id: command.id, isEnabled: command.isEnabled,
                           name: command.name, source: .inline(input))
        })
        .font(Font.system(.body, design: .monospaced))
        .cornerRadius(8)
        .padding()
      }
    }
    .enableInjection()
  }

  var filePicker: some View {
    VStack {
      LazyVGrid(columns: [
        GridItem(.fixed(50), alignment: .trailing),
        GridItem(.flexible())
      ], content: {
        Text("Name:")
        TextField(command.name, text: Binding(get: {
          command.hasName ? command.name : ""
        }, set: {
          command = .shell(id: command.id, isEnabled: command.isEnabled,
                           name: $0.isEmpty ? nil : $0,
                           source: .path(command.path))
        }))

        Text("Path:")
        TextField("file://", text: Binding<String>(get: {
          filePath
        }, set: {
          filePath = $0
          command = .shell(id: command.id, isEnabled: command.isEnabled,
                           name: command.name,
                           source: .path($0))
        }))
      })

      HStack {
        Spacer()
        Button("Browse", action: {
          openPanelController.perform(.selectFile(type: "sh", handler: {
            let newCommand = ScriptCommand.shell(id: command.id,
                                                 isEnabled: command.isEnabled,
                                                 name: command.name,
                                                 source: .path($0))
            command = newCommand
            filePath = newCommand.path
          }))
        })
      }
    }
    .padding()
  }
}

struct EditShellScriptView_Previews: PreviewProvider {
  static var previews: some View {
    EditShellScriptView(command: .empty(.shell), openPanelController: OpenPanelController(), update: { _ in })
  }
}
