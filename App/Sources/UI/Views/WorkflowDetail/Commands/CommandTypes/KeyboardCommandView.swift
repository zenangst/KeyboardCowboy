import Bonzai
import HotSwiftUI
import SwiftUI

struct KeyboardCommandView: View {
  private let focus: FocusState<AppFocus?>.Binding
  private let iconSize: CGSize
  private let metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.KeyboardModel

  init(_ focus: FocusState<AppFocus?>.Binding, metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.KeyboardModel, iconSize: CGSize) {
    self.focus = focus
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
  }

  var body: some View {
    KeyboardCommandInternalView(focus, metaData: metaData, model: model, iconSize: iconSize)
  }
}

struct KeyboardCommandInternalView: View {
  @EnvironmentObject var openWindow: WindowOpener
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Binding private var model: CommandViewModel.Kind.KeyboardModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.KeyboardModel,
       iconSize: CGSize) {
    self.focus = focus
    self.metaData = metaData
    _model = Binding<CommandViewModel.Kind.KeyboardModel>(model)
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { KeyboardCommandIconView(iconSize: iconSize) },
      content: {
        ContentView(model: $model, focus: focus) {
          openWindow.openNewCommandWindow(.editCommand(workflowId: transaction.workflowID, commandId: metaData.id))
        }
        .frame(height: 32)
      },
      subContent: {
        Spacer()
        Menu {
          ForEach(1 ..< 20, id: \.self) { iteration in
            Button {
              updater.modifyCommand(withID: metaData.id, using: transaction) { command in
                guard case let .keyboard(keyboardCommand) = command,
                      case var .key(keyboardCommand) = keyboardCommand.kind else { return }

                keyboardCommand.iterations = iteration
                command = .keyboard(.init(id: command.id, name: command.name, kind: .key(command: keyboardCommand),
                                          notification: command.notification, meta: command.meta))
              }
            } label: {
              Text("\(iteration)")
                .underline(model.command.iterations == iteration)
            }
          }
          .font(.caption)
        } label: {
          Image(systemName: "repeat")
          Text("Iterations \(model.command.iterations)")
            .font(.caption)
        }
        .fixedSize()

        KeyboardCommandSubContentView {
          openWindow.openNewCommandWindow(.editCommand(workflowId: transaction.workflowID, commandId: metaData.id))
        }
      },
    )
  }
}

private struct KeyboardCommandIconView: View {
  let iconSize: CGSize

  var body: some View {
    KeyboardIconView(size: iconSize.width)
      .overlay {
        Image(systemName: "flowchart")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: iconSize.width / 2)
      }
  }
}

private struct ContentView: View {
  @StateObject private var keyboardSelection = SelectionManager<KeyShortcut>()
  @Binding private var model: CommandViewModel.Kind.KeyboardModel
  private let focus: FocusState<AppFocus?>.Binding
  private let onEdit: () -> Void

  init(model: Binding<CommandViewModel.Kind.KeyboardModel>,
       focus: FocusState<AppFocus?>.Binding,
       onEdit: @escaping () -> Void) {
    _model = model
    self.focus = focus
    self.onEdit = onEdit
  }

  var body: some View {
    EditableKeyboardShortcutsView<AppFocus>(
      focus,
      focusBinding: { .detail(.commandShortcut($0)) },
      mode: .externalEdit(onEdit),
      keyboardShortcuts: $model.command.keyboardShortcuts,
      draggableEnabled: false,
      selectionManager: keyboardSelection,
      onTab: { _ in },
    )
    .font(.caption)
    .scrollDisabled(true)
  }
}

private struct KeyboardCommandSubContentView: View {
  private let onEdit: () -> Void

  init(onEdit: @escaping () -> Void) {
    self.onEdit = onEdit
  }

  var body: some View {
    Button(action: onEdit) { Text("Edit").font(.caption) }
      .font(.caption)
  }
}

struct RebindingCommandView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static let recorderStore = KeyShortcutRecorderStore()
  static let command = DesignTime.rebindingCommand
  static var previews: some View {
    KeyboardCommandView(
      $focus,
      metaData: command.model.meta,
      model: command.kind,
      iconSize: .init(width: 24, height: 24),
    )
    .designTime()
    .environmentObject(recorderStore)
  }
}
