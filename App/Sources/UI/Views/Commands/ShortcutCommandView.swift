import SwiftUI

struct ShortcutCommandView: View {
  enum Action {
    case updateName(newName: String)
    case openShortcuts
    case commandAction(CommandContainerAction)
  }

  @State private var name: String
  @State var command: DetailViewModel.CommandViewModel
  @State var notify: Bool = false
  private let onAction: (Action) -> Void

  init(_ command: DetailViewModel.CommandViewModel,
       onAction: @escaping (Action) -> Void) {
    _command = .init(initialValue: command)
    _name = .init(initialValue: command.name)
    _notify = .init(initialValue: command.notify)
    self.onAction = onAction
  }
  
  var body: some View {
    CommandContainerView($command, icon: { command in
      ZStack {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Shortcuts.app"))
      }
    }, content: { command in
      TextField("", text: $name)
        .textFieldStyle(AppTextFieldStyle())
        .onChange(of: name, perform: {
          onAction(.updateName(newName: $0))
        })
    }, subContent: { command in
      HStack {
        Button("Open Shortcuts", action: { onAction(.openShortcuts) })
          .buttonStyle(GradientButtonStyle(.init(nsColor: .systemPurple, grayscaleEffect: true)))
          .font(.caption)
      }
    }, onAction: { onAction(.commandAction($0)) })
    .debugEdit()
  }
}

struct ShortcutCommandView_Previews: PreviewProvider {
  static var previews: some View {
    ShortcutCommandView(DesignTime.shortcutCommand, onAction: { _ in})
      .frame(maxHeight: 80)
  }
}
