import Inject
import SwiftUI

struct NewCommandScriptView: View {
  @ObserveInjection var inject

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

    var syntax: any SyntaxHighlighting {
      switch self {
      case .appleScript:
        return AppleScriptHighlighting()
      case .shellScript:
        return ShellScriptHighlighting()
      }
    }
  }

  @EnvironmentObject var openPanel: OpenPanelController
  @State private var kind: Kind
  @State private var scriptExtension: ScriptExtension
  @State private var value: String
  @Binding private var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation

  init(_ payload: Binding<NewCommandPayload>,
       kind: Kind,
       value: String,
       scriptExtension: ScriptExtension,
       validation: Binding<NewCommandValidation>) {
    _kind = .init(initialValue: kind)
    _scriptExtension = .init(initialValue: scriptExtension)
    _value = .init(initialValue: value)
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
        NewCommandFileSelectorView($scriptExtension, path: value) { path in
          value = path
          validation = updateAndValidatePayload()
        }
        .overlay(NewCommandValidationView($validation))
      case .source:
        VStack {
          NewCommandScriptSourceView($scriptExtension, text: value) { newString in
            value = newString
            validation = updateAndValidatePayload()
          }
          .overlay(NewCommandValidationView($validation))
        }
      }
    }
    .onChange(of: validation, perform: { newValue in
      guard newValue == .needsValidation else { return }
      validation = updateAndValidatePayload()
    })
    .onAppear {
      validation = .unknown
    }
    .menuStyle(.borderlessButton)
    .enableInjection()
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    switch kind {
    case .file:
      payload = .script(value: value, kind: kind, scriptExtension: scriptExtension)
      if value.hasSuffix(scriptExtension.rawValue) {
        return .valid
      } else {
        return .invalid(reason: "Wrong file extension.")
      }
    case .source:
      payload = .script(value: value, kind: kind, scriptExtension: scriptExtension)
      return .valid
    }
  }
}

struct NewCommandFileSelectorView: View {
  @EnvironmentObject var openPanel: OpenPanelController
  @State var path: String = "~/"

  @Binding private var scriptExtension: NewCommandScriptView.ScriptExtension
  private var onPathChange: (String) -> Void

  init(_ scriptExtension: Binding<NewCommandScriptView.ScriptExtension>,
       path: String,
       onPathChange: @escaping (String) -> Void) {
    _path = .init(initialValue: path)
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

  init(_ kind: Binding<NewCommandScriptView.ScriptExtension>,
       text: String,
       onChange: @escaping (String) -> Void) {
    _text = .init(initialValue: text)
    _kind = kind
    self.onChange = onChange
  }

  var body: some View {
    ScriptEditorView(text: $text, syntax: Binding(get: { kind.syntax }, set: { _ in }))
      .onChange(of: text, perform: onChange)
  }
}

//struct NewCommandScriptView_Previews: PreviewProvider {
//  static var previews: some View {
//    NewCommandScriptView()
//  }
//}
