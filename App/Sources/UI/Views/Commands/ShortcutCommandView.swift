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

  @State private var model: CommandViewModel.Kind.ShortcutModel

  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize
  private let debounce: DebounceManager<String>
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.ShortcutModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    _model = .init(initialValue: model)
    self.metaData = metaData
    self.iconSize = iconSize
    self.onAction = onAction
    self.debounce = DebounceManager(for: .milliseconds(500), onUpdate: { value in
      onAction(.updateName(newName: value))
    })
  }
  
  var body: some View {
    CommandContainerView(metaData, placeholder: model.placeholder, icon: { metaData in
      ShortcutCommandIconView(iconSize: iconSize)
    }, content: { command in
      ShortcutCommandContentView(model: $model) { shortcut in
        onAction(.updateShortcut(shortcutName: shortcut.name))
      }
    }, subContent: { command in
      ShortcutCommandSubContentView {
        onAction(.openShortcut)
      } onCreateShortcut: {
        onAction(.createShortcut)
      }

    }, onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

private struct ShortcutCommandIconView: View {
  private let iconSize: CGSize

  init(iconSize: CGSize) {
    self.iconSize = iconSize
  }

  var body: some View {
    IconView(icon: .init(bundleIdentifier: "/System/Applications/Shortcuts.app",
                         path: "/System/Applications/Shortcuts.app"),
             size: iconSize)
  }
}

private struct ShortcutCommandContentView: View {
  @EnvironmentObject private var shortcutStore: ShortcutStore
  @Binding private var model: CommandViewModel.Kind.ShortcutModel
  private let onSelect: (Shortcut) -> Void

  init(model: Binding<CommandViewModel.Kind.ShortcutModel>,
       onSelect: @escaping (Shortcut) -> Void) {
    _model = model
    self.onSelect = onSelect
  }

  var body: some View {
    VStack {
      Menu(content: {
        ForEach(shortcutStore.shortcuts, id: \.name) { shortcut in
          Button(action: {
            model.shortcutIdentifier = shortcut.name
            onSelect(shortcut)
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
  }
}


private struct ShortcutCommandSubContentView: View {
  private let onOpenShortcut: () -> Void
  private let onCreateShortcut: () -> Void

  init(onOpenShortcut: @escaping () -> Void,
       onCreateShortcut: @escaping () -> Void) {
    self.onOpenShortcut = onOpenShortcut
    self.onCreateShortcut = onCreateShortcut
  }

  var body: some View {
    HStack {
      Button("Open Shortcut", action: onOpenShortcut)
        .buttonStyle(.zen(.init(color: .systemPurple, grayscaleEffect: .constant(true))))
        .font(.caption)

      Button("Create Shortcut", action: onCreateShortcut)
        .buttonStyle(.zen(.init(color: .systemPurple, grayscaleEffect: .constant(true))))
        .font(.caption)
    }
  }
}

struct ShortcutCommandView_Previews: PreviewProvider {
  static let command = DesignTime.shortcutCommand
  static var previews: some View {
    ShortcutCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) { _ in }
      .frame(maxHeight: 100)
      .designTime()
  }
}
