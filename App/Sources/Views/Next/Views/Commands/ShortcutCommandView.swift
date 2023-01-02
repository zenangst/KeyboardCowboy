import SwiftUI

struct ShortcutCommandView: View {
  enum Action {
    case updateName(newName: String)
    case openShortcuts
    case commandAction(CommandContainerAction)
  }

  @ObserveInjection var inject
  @State private var name: String
  @Binding var command: DetailViewModel.CommandViewModel
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       onAction: @escaping (Action) -> Void) {
    _command = command
    _name = .init(initialValue: command.wrappedValue.name)
    self.onAction = onAction
  }
  
  var body: some View {
    CommandContainerView(isEnabled: $command.isEnabled, icon: {
      Rectangle()
        .fill(Color(nsColor: .controlAccentColor).opacity(0.375))
        .cornerRadius(8, antialiased: false)
      Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Shortcuts.app"))
    }, content: {
      TextField("", text: $name)
        .textFieldStyle(AppTextFieldStyle())
        .onChange(of: name, perform: {
          onAction(.updateName(newName: $0))
        })
    }, subContent: {
      Button("Open Shortcuts", action: { onAction(.openShortcuts) })
    }, onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

struct ShortcutCommandView_Previews: PreviewProvider {
  static var previews: some View {
    ShortcutCommandView(.constant(DesignTime.shortcutCommand), onAction: { _ in})
  }
}
