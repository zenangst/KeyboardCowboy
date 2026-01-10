import Bonzai
import HotSwiftUI
import SwiftUI

struct ShortcutCommandView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @State private var model: CommandViewModel.Kind.ShortcutModel

  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.ShortcutModel, iconSize: CGSize) {
    _model = .init(initialValue: model)
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(metaData, placeholder: model.placeholder, icon: {
      ShortcutCommandIconView(iconSize: iconSize)
    }, content: {
      ShortcutCommandContentView(model: $model) { shortcut in
        updater.modifyCommand(withID: metaData.id, using: transaction) { command in
          guard case var .shortcut(shortcutCommand) = command else { return }

          shortcutCommand.name = shortcut.name
          command = .shortcut(shortcutCommand)
        }
      }
    }, subContent: {
      Spacer()
      ShortcutCommandSubContentView {
        try? SBShortcuts.createShortcut()
      } onCreateShortcut: {
        try? SBShortcuts.openShortcut(metaData.name)
      }

    })
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
      Button("Create Shortcut", action: onCreateShortcut)
    }
  }
}

struct ShortcutCommandView_Previews: PreviewProvider {
  static let command = DesignTime.shortcutCommand
  static var previews: some View {
    ShortcutCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24))
      .designTime()
  }
}
