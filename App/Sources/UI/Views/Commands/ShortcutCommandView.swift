import Bonzai
import Inject
import SwiftUI

struct ShortcutCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case updateName(newName: String)
    case updateShortcut(shortcutName: String)
    case createShortcut
    case openShortcut
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

        IconView(icon: .init(bundleIdentifier: "/System/Applications/Shortcuts.app", 
                             path: "/System/Applications/Shortcuts.app"),
                 size: .init(width: 32, height: 32))
      }
    }, content: { command in
      VStack {
        TextField("", text: $metaData.name)
          .textFieldStyle(.regular(Color(.windowBackgroundColor)))
          .onChange(of: metaData.name, perform: { debounce.send($0) })
        Menu(content: {
          ForEach(shortcutStore.shortcuts, id: \.name) { shortcut in
            Button(action: {
              model.shortcutIdentifier = shortcut.name
              onAction(.updateShortcut(shortcutName: shortcut.name))
            }, label: {
              Text(shortcut.name)
                .font(.subheadline)
            })
          }
        }, label: {
          Text(model.shortcutIdentifier)
            .font(.subheadline)
        })
        .menuStyle(.zen(.init(color: .systemPurple, grayscaleEffect: .constant(true))))
        .padding(.bottom, 4)
      }
    }, subContent: { command in
      HStack {
        Button("Open Shortcut", action: { onAction(.openShortcut) })
          .buttonStyle(.zen(.init(color: .systemPurple, grayscaleEffect: .constant(true))))
          .font(.caption)

        Button("Create Shortcut", action: { onAction(.createShortcut) })
          .buttonStyle(.zen(.init(color: .systemPurple, grayscaleEffect: .constant(true))))
          .font(.caption)
      }
    }, onAction: { onAction(.commandAction($0)) })
    .enableInjection()
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
