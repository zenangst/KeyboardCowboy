import SwiftUI

struct ScriptCommandView: View {
  enum Action {
    case updateName(newName: String)
    case updateSource(kind: DetailViewModel.CommandViewModel.ScriptKind)
    case open(path: String)
    case reveal(path: String)
    case edit
    case commandAction(CommandContainerAction)
  }
  @EnvironmentObject var openPanel: OpenPanelController
  @State private var name: String
  @State private var text: String
  @State private var command: DetailViewModel.CommandViewModel
  private let onAction: (Action) -> Void

  init(_ command: DetailViewModel.CommandViewModel, onAction: @escaping (Action) -> Void) {
    _command = .init(initialValue: command)
    _name = .init(initialValue: command.name)
    self.onAction = onAction
    switch command.kind {
    case .script(let kind):
      _text = .init(initialValue: kind.source)
    default:
      _text = .init(initialValue: "")
    }
  }

  var body: some View {
    CommandContainerView($command, icon: { command in
      ZStack {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Script Editor.app"))
          .resizable()
          .aspectRatio(1, contentMode: .fill)
          .frame(width: 32)
      }
    }, content: { command in
      VStack {
        HStack(spacing: 8) {
          TextField("", text: $name)
            .textFieldStyle(AppTextFieldStyle())
            .onChange(of: name, perform: {
              onAction(.updateName(newName: $0))
            })
          Spacer()
        }

        if case .script(let kind) = command.wrappedValue.kind {
          switch kind {
          case .inline(let id, _, let scriptExtension):
            ScriptEditorView(text: $text, syntax: .constant(AppleScriptHighlighting()))
              .onChange(of: text) { newSource in
                onAction(.updateSource(kind: .inline(id: id, source: newSource, scriptExtension: scriptExtension)))
              }
          case .path(let id, _, let scriptExtension):
            HStack {
              TextField("Path", text: $text)
                .textFieldStyle(FileSystemTextFieldStyle())
                .onChange(of: text) { newPath in
                  self.text = newPath
                  onAction(.updateSource(kind: .path(id: id, source: newPath, scriptExtension: scriptExtension)))
                }
              Button("Browse", action: {
                openPanel.perform(.selectFile(type: scriptExtension.rawValue, handler: { newPath in
                  self.text = newPath
                  onAction(.updateSource(kind: .path(id: id, source: newPath, scriptExtension: scriptExtension)))
                }))
              })
              .buttonStyle(.gradientStyle(config: .init(nsColor: .systemBlue, grayscaleEffect: true)))
              .font(.caption)
            }
          }
        }
      }
    }, subContent: { command in
      HStack {
        if case .script(let kind) = command.wrappedValue.kind {
          switch kind {
          case .inline:
            EmptyView()
          case .path(_, let source, _):
            Button("Open", action: { onAction(.open(path: source)) })
              .buttonStyle(.gradientStyle(config: .init(nsColor: .systemCyan, grayscaleEffect: true)))
            Button("Reveal", action: { onAction(.reveal(path: source)) })
              .buttonStyle(.gradientStyle(config: .init(nsColor: .systemBlue, grayscaleEffect: true)))
          }
        }
      }
      .font(.caption)
    }, onAction: { onAction(.commandAction($0)) })
    .debugEdit()
  }
}

struct ScriptCommandView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      ScriptCommandView(DesignTime.scriptCommandInline, onAction: { _ in })
        .frame(maxHeight: 80)
      Divider()
      ScriptCommandView(DesignTime.scriptCommandWithPath, onAction: { _ in })
        .frame(maxHeight: 80)
    }
  }
}
