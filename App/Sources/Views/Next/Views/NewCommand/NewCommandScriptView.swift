import SwiftUI

struct NewCommandScriptView: View {
  enum Kind {
    case file(path: String, extension: ScriptExtension)
    case source(contents: String, extension: ScriptExtension)
  }

  enum ScriptExtension: String {
    case shellScript = "sh"
    case appleScript = "scpt"
  }

  @EnvironmentObject var openPanel: OpenPanelController
  @State private var kind: Kind = .file(path: "~/", extension: .shellScript)
  @Binding private var payload: NewCommandPayload
  @Binding private var validation: NewCommandView.Validation

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandView.Validation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      Label(title: { Text("Open file or folder:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())

      switch kind {
      case .file(_, let fileExtension):
        NewCommandFileSelectorView(fileExtension.rawValue) { path in

        }
      case .source(_, let fileExtension):
        NewCommandScriptSourceView()
      }
    }
  }
}

struct NewCommandFileSelectorView: View {
  @EnvironmentObject var openPanel: OpenPanelController
  @State var path: String = "~/"

  private let fileType: String
  private var onPathChange: (String) -> Void

  init(_ fileType: String, onPathChange: @escaping (String) -> Void) {
    self.onPathChange = onPathChange
    self.fileType = fileType
  }

  var body: some View {
    HStack {
      TextField("Path", text: $path)
        .textFieldStyle(FileSystemTextFieldStyle())
        .onChange(of: path) { newPath in
          onPathChange(newPath)
        }
      Button("Browse", action: {
        openPanel.perform(.selectFile(type: fileType, handler: { newPath in
          self.path = newPath
          onPathChange(newPath)
        }))
      })
      .buttonStyle(.gradientStyle(config: .init(nsColor: .systemBlue, grayscaleEffect: true)))
    }
  }
}

struct NewCommandScriptSourceView: View {
  var body: some View {
    Text("Source!")
  }
}

//struct NewCommandScriptView_Previews: PreviewProvider {
//  static var previews: some View {
//    NewCommandScriptView()
//  }
//}
