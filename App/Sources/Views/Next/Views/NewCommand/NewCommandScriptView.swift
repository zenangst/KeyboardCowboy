import SwiftUI

struct NewCommandScriptView: View {
  enum Kind: String, CaseIterable, Hashable, Identifiable {
    var id: String { rawValue }
    case file = "File"
    case source = "Source"
  }

  enum ScriptExtension: String, CaseIterable, Hashable, Identifiable {
    var id: String { rawValue }

    // TODO: Add support for `.swift`
    case appleScript = "scpt"
    case shellScript = "sh"

    var displayName: String {
      switch self {
      case .shellScript:
        return "Shellscript"
      case .appleScript:
        return "AppleScript"
      }
    }

    var syntax: SyntaxHighlighting {
      switch self {
      case .appleScript:
        return AppleScriptHighlighting()
      case .shellScript:
        return ShellScriptHighlighting()
      }
    }
  }

  @ObserveInjection var inject
  @EnvironmentObject var openPanel: OpenPanelController
  @State private var kind: Kind = .file
  @State private var scriptExtension: ScriptExtension = .appleScript
  @Binding private var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      Label(title: { Text("Open file or folder:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())

      HStack {
        Menu(content: {
          ForEach(ScriptExtension.allCases) { scriptExtension in
            Button(action: { self.scriptExtension = scriptExtension }, label: {
              Text(scriptExtension.displayName)
            })
          }
        }, label: {
          Text(scriptExtension.displayName)
        })
        .padding(4)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.windowBackgroundColor), lineWidth: 1)
            .frame(height: 40)
        )

        Menu(content: {
          ForEach(Kind.allCases) { kind in
            Button(action: { self.kind = kind }, label: {
              Text(kind.rawValue)
            })
          }
        }, label: {
          switch kind {
          case .file:
            Text("File")
          case .source:
            Text("Inline")
          }
        })
        .padding(4)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.windowBackgroundColor), lineWidth: 1)
            .frame(height: 40)
        )
      }
      .padding(.vertical)

      switch kind {
      case .file:
        NewCommandFileSelectorView($scriptExtension) { path in }
      case .source:
        NewCommandScriptSourceView($scriptExtension) { newString in }
      }
    }
    .menuStyle(.borderlessButton)
    .enableInjection()
  }
}

struct NewCommandFileSelectorView: View {
  @EnvironmentObject var openPanel: OpenPanelController
  @State var path: String = "~/"

  @Binding private var scriptExtension: NewCommandScriptView.ScriptExtension
  private var onPathChange: (String) -> Void

  init(_ scriptExtension: Binding<NewCommandScriptView.ScriptExtension>, onPathChange: @escaping (String) -> Void) {
    self.onPathChange = onPathChange
    _scriptExtension = scriptExtension
  }

  var body: some View {
    HStack {
      TextField("Path", text: $path)
        .textFieldStyle(FileSystemTextFieldStyle())
        .onChange(of: path) { newPath in
          onPathChange(newPath)
        }
      Button("Browse", action: {
        openPanel.perform(.selectFile(type: scriptExtension.rawValue, handler: { newPath in
          self.path = newPath
          onPathChange(newPath)
        }))
      })
      .buttonStyle(.gradientStyle(config: .init(nsColor: .systemBlue, grayscaleEffect: true)))
    }
  }
}

struct NewCommandScriptSourceView: View {
  @State var text: String = ""
  @Binding private var kind: NewCommandScriptView.ScriptExtension
  private let onChange: (String) -> Void

  init(_ kind: Binding<NewCommandScriptView.ScriptExtension>, onChange: @escaping (String) -> Void) {
    _kind = kind
    self.onChange = onChange
  }

  var body: some View {
    let _ = Swift.print(kind.syntax)
    ScriptEditorView(text: $text, syntax: Binding(get: { kind.syntax }, set: { _ in }))
      .onChange(of: text, perform: onChange)
  }
}

//struct NewCommandScriptView_Previews: PreviewProvider {
//  static var previews: some View {
//    NewCommandScriptView()
//  }
//}
