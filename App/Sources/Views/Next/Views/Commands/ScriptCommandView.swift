import SwiftUI

struct ScriptCommandView: View {
  enum Action {
    case updateName(newName: String)
    case open(path: String)
    case reveal(path: String)
    case edit
    case commandAction(CommandContainerAction)
  }
  @ObserveInjection var inject
  @State private var name: String
  @State private var text: String
  @Binding private var command: DetailViewModel.CommandViewModel
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>, onAction: @escaping (Action) -> Void) {
    _command = command
    _name = .init(initialValue: command.name.wrappedValue)
    self.onAction = onAction

    switch command.kind.wrappedValue {
    case .script(let kind):
      switch kind {
      case .inline(_, let source, _):
        _text = .init(initialValue: source)
      case .path(_, let source, _):
        _text = .init(initialValue: source)
      }
      break
    default:
      _text = .init(initialValue: "")
    }

  }

  var body: some View {
    CommandContainerView(isEnabled: $command.isEnabled, icon: {
      Rectangle()
        .fill(Color(nsColor: .controlAccentColor).opacity(0.375))
        .cornerRadius(8, antialiased: false)
      Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Script Editor.app"))
        .resizable()
        .aspectRatio(1, contentMode: .fill)
        .frame(width: 32)
    }, content: {
      VStack {
        HStack(spacing: 8) {
          TextField("", text: $name)
            .textFieldStyle(AppTextFieldStyle())
            .onChange(of: name, perform: {
              onAction(.updateName(newName: $0))
            })
          Spacer()
        }
        ScriptEditorView(text: $text, syntax: .constant(AppleScriptHighlighting()))
      }
    }, subContent: {
      HStack {
        if case .script(let kind) = command.kind {
          switch kind {
          case .inline:
            EmptyView()
          case .path(_, let source, _):
            Button("Open", action: { onAction(.open(path: source)) })
            Button("Reveal", action: { onAction(.reveal(path: source)) })
          }
        }
      }
      .font(.caption)
    }, onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

struct ScriptCommandView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      ScriptCommandView(.constant(DesignTime.scriptCommandInline), onAction: { _ in })
        .frame(maxHeight: 80)
      Divider()
      ScriptCommandView(.constant(DesignTime.scriptCommandWithPath), onAction: { _ in })
        .frame(maxHeight: 80)
    }
  }
}
