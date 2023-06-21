import SwiftUI

struct ShortcutCommandView: View {
  enum Action {
    case updateName(newName: String)
    case updateShortcut(shortcutName: String)
    case openShortcuts
    case commandAction(CommandContainerAction)
  }

  @EnvironmentObject var shortcutStore: ShortcutStore
  @State var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.ShortcutModel

  private let debounce: DebounceManager<String>
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.ShortcutModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.onAction = onAction
    self.debounce = DebounceManager(for: .milliseconds(500), onUpdate: { value in
      onAction(.updateName(newName: value))
    })
  }
  
  var body: some View {
    CommandContainerView($metaData, icon: { metaData in
      ZStack {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Shortcuts.app"))
      }
    }, content: { command in
      VStack {
        TextField("", text: $metaData.name)
          .textFieldStyle(AppTextFieldStyle())
          .onChange(of: metaData.name, perform: { debounce.send($0) })
        Menu(model.shortcutIdentifier) {
          ForEach(shortcutStore.shortcuts, id: \.name) { shortcut in
            Button(shortcut.name, action: {
              model.shortcutIdentifier = shortcut.name
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
  static let command = DesignTime.shortcutCommand
  static var previews: some View {
    ShortcutCommandView(command.model.meta, model: command.kind) { _ in }
      .frame(maxHeight: 100)
      .designTime()
  }
}
