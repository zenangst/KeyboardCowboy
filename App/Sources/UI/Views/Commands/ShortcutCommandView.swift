import SwiftUI

struct ShortcutCommandView: View {
  enum Action {
    case updateName(newName: String)
    case updateShortcut(shortcutName: String)
    case openShortcuts
    case commandAction(CommandContainerAction)
  }

  @EnvironmentObject var shortcutStore: ShortcutStore
  @State private var name: String
  @State private var shortcut: String
  @State var command: DetailViewModel.CommandViewModel

  private let debounce: DebounceManager<String>
  private let onAction: (Action) -> Void

  init(_ command: DetailViewModel.CommandViewModel,
       onAction: @escaping (Action) -> Void) {
    _command = .init(initialValue: command)
    _name = .init(initialValue: command.name)

    if case .shortcut(let name) = command.kind {
      _shortcut = .init(initialValue: name)
    } else {
      _shortcut = .init(initialValue: "")
    }

    self.onAction = onAction
    self.debounce = DebounceManager(for: .milliseconds(500), onUpdate: { value in
      onAction(.updateName(newName: value))
    })
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
      VStack {
        TextField("", text: $name)
          .textFieldStyle(AppTextFieldStyle())
          .onChange(of: name, perform: { debounce.send($0) })
        Menu(shortcut) {
          ForEach(shortcutStore.shortcuts, id: \.name) { shortcut in
            Button(shortcut.name, action: {
              self.shortcut = shortcut.name
              onAction(.updateShortcut(shortcutName: shortcut.name))
            })
          }
        }
        .menuStyle(GradientMenuStyle(.init(nsColor: .systemPurple, grayscaleEffect: true), fixedSize: false))
        .padding(.bottom, 4)
      }
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
      .frame(maxHeight: 100)
      .designTime()
  }
}
