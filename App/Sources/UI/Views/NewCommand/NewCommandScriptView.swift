import Bonzai
import HotSwiftUI
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
      case .shellScript: "Shellscript"
      case .appleScript: "AppleScript"
      }
    }
  }

  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#open-commands")!

  @EnvironmentObject var openPanel: OpenPanelController
  @State private var kind: Kind
  @State private var scriptExtension: ScriptExtension
  @State private var value: String
  @Binding private var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation
  private let onSubmit: (NewCommandPayload) -> Void

  init(_ payload: Binding<NewCommandPayload>,
       kind: Kind,
       value: String,
       scriptExtension: ScriptExtension,
       validation: Binding<NewCommandValidation>,
       onSubmit: @escaping (NewCommandPayload) -> Void)
  {
    _kind = .init(initialValue: kind)
    _scriptExtension = .init(initialValue: scriptExtension)
    _value = .init(initialValue: value)
    _payload = payload
    _validation = validation
    self.onSubmit = onSubmit
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ZenLabel("Scripts:")
        Spacer()
        Button(action: { NSWorkspace.shared.open(wikiUrl) },
               label: { Image(systemName: "questionmark.circle.fill") })
      }

      HStack {
        ScriptIconView(size: 24)
        Menu(content: {
          ForEach(ScriptExtension.allCases) { scriptExtension in
            Button(action: { self.scriptExtension = scriptExtension }, label: {
              Text(scriptExtension.displayName)
            })
          }
        }, label: {
          Text(scriptExtension.displayName)
        })

        Menu(content: {
          ForEach(Kind.allCases) { kind in
            Button(action: {
              self.kind = kind
              payload = .script(value: value, kind: kind, scriptExtension: scriptExtension)
            }, label: {
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
      }
      .padding(.vertical, 8)

      switch kind {
      case .file:
        NewCommandFileSelectorView($scriptExtension, path: value) { path in
          value = path
          validation = updateAndValidatePayload()
        }
        .overlay(NewCommandValidationView($validation))
      case .source:
        NewCommandScriptSourceView($scriptExtension, text: value, onSubmit: {
          if case .valid = validation {
            onSubmit(payload)
          }
        }) { newString in
          value = newString
          validation = updateAndValidatePayload()
        }
        .overlay(NewCommandValidationView($validation))
      }
    }
    .onChange(of: validation, perform: { newValue in
      guard newValue == .needsValidation else { return }

      validation = updateAndValidatePayload()
    })
    .onAppear {
      validation = .unknown
    }
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
       onPathChange: @escaping (String) -> Void)
  {
    _path = .init(initialValue: path)
    self.onPathChange = onPathChange
    _scriptExtension = scriptExtension
  }

  var body: some View {
    HStack {
      TextField("Path", text: $path)
        .onChange(of: path) { newPath in
          onPathChange(newPath)
        }
      Button("Browse", action: {
        openPanel.perform(.selectFile(types: [scriptExtension.rawValue], handler: { newPath in
          path = newPath
          onPathChange(newPath)
        }))
      })
    }
  }
}

struct NewCommandScriptSourceView: View {
  @State var text: String = ""
  @Binding private var kind: NewCommandScriptView.ScriptExtension
  private let onSubmit: () -> Void
  private let onChange: (String) -> Void

  init(_ kind: Binding<NewCommandScriptView.ScriptExtension>,
       text: String,
       onSubmit: @escaping () -> Void,
       onChange: @escaping (String) -> Void)
  {
    _text = .init(initialValue: text)
    _kind = kind
    self.onChange = onChange
    self.onSubmit = onSubmit
  }

  var body: some View {
    ZenTextEditor(
      text: $text,
      placeholder: "Script goes here…",
      font: Font.system(.body, design: .monospaced),
      onCommandReturnKey: onSubmit,
    )
    .onChange(of: text, perform: onChange)
    .roundedStyle(padding: 8)
  }
}

struct NewCommandScriptView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .script,
      payload: .placeholder,
      onDismiss: {},
      onSave: { _, _ in },
    )
    .designTime()
  }
}
