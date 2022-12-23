import SwiftUI

struct ScriptCommandView: View {
  enum Action {
    case updateName(newName: String)
    case open
    case reveal
    case edit
    case commandAction(CommandContainerAction)
  }
  @ObserveInjection var inject
  @State private var name: String
  @Binding private var command: DetailViewModel.CommandViewModel
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>, onAction: @escaping (Action) -> Void) {
    _command = command
    _name = .init(initialValue: command.name.wrappedValue)
    self.onAction = onAction
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
      HStack(spacing: 8) {
        TextField("", text: $name)
          .textFieldStyle(KCTextFieldStyle())
          .onChange(of: name, perform: {
            onAction(.updateName(newName: $0))
          })
        Spacer()
      }
    }, subContent: {
      HStack {
        if case .script(let kind) = command.kind {
          switch kind {
          case .inline:
            Button("Edit", action: { onAction(.edit) })
          case .path:
            Button("Open", action: { onAction(.open) })
            Button("Reveal", action: { onAction(.reveal) })
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
