import Bonzai
import Inject
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
      },
      subContent: {
        Menu {
          Button(action: {
            updater.modifyCommand(withID: metaData.id, using: transaction) { command in
              command.notification = .none
            }
          }, label: { Text("None") })
          ForEach(Command.Notification.regularCases) { notification in
            Button(action: {
              updater.modifyCommand(withID: metaData.id, using: transaction) { command in
                command.notification = notification
              }
            }, label: { Text(notification.displayValue) })
          }
        } label: {
          switch metaData.notification {
          case .bezel:        Text("Bezel").font(.caption)
          case .capsule:      Text("Capsule").font(.caption)
          case .commandPanel: Text("Command Panel").font(.caption)
          case .none:         Text("None").font(.caption)
          }
        }
        .fixedSize()

        Spacer()

        Menu {
          ForEach(1..<20, id: \.self) { iteration in
            Button {
              updater.modifyCommand(withID: metaData.id, using: transaction) { command in
                guard case .keyboard(var keyboardCommand) = command else { return }
                keyboardCommand.iterations = iteration
                command = .keyboard(keyboardCommand)
              }
            } label: {
                Text("\(iteration)")
                .underline(model.iterations == iteration)
            }
          }
          .font(.caption)
        } label: {
          Image(systemName: "repeat")
          Text("Iterations \(model.iterations)")
            .font(.caption)
        }
        .fixedSize()

        KeyboardCommandSubContentView {
          openWindow.openNewCommandWindow(.editCommand(workflowId: transaction.workflowID, commandId: metaData.id))
        }
      })
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
      keyboardShortcuts: $model.keys,
      draggableEnabled: false,
      selectionManager: keyboardSelection,
      onTab: { _ in })
    .font(.caption)
  }
}

private struct KeyboardCommandSubContentView: View {
  private let onEdit: () -> Void

  init(onEdit: @escaping () -> Void) {
    self.onEdit = onEdit
  }

  var body: some View {
    HStack {
      Button(action: onEdit) { Text("Edit") }
        .font(.caption)
    }
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
      iconSize: .init(width: 24, height: 24)
    ) 
      .designTime()
      .environmentObject(recorderStore)
      .frame(maxHeight: 120)
  }
}
