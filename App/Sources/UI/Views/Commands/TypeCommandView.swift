import Bonzai
import Inject
import SwiftUI

struct TypeCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case updateName(newName: String)
    case updateSource(newInput: String)
    case updateMode(newMode: TextCommand.TypeCommand.Mode)
    case commandAction(CommandContainerAction)
  }
  private let metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.TypeModel
  private let onAction: (Action) -> Void
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.TypeModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { metaData in
        TypingIconView(size: iconSize.width)
      }, content: { metaData in
        TypeCommandContentView(model, onAction: onAction)
          .roundedContainer(4, padding: 0, margin: 0)
      }, subContent: { metaData in
        HStack {
          ZenCheckbox("Notify", style: .small, isOn: Binding(get: {
            if case .bezel = metaData.notification.wrappedValue { return true } else { return false }
          }, set: { newValue in
            metaData.notification.wrappedValue = newValue ? .bezel : nil
            onAction(.commandAction(.toggleNotify(newValue ? .bezel : nil)))
          })) { value in
            if value {
              onAction(.commandAction(.toggleNotify(metaData.notification.wrappedValue)))
            } else {
              onAction(.commandAction(.toggleNotify(nil)))
            }
          }
          .offset(x: 1)

          Spacer()

          TypeCommandModeView(mode: model.mode) { newMode in
            onAction(.updateMode(newMode: newMode))
          }
        }
      }, onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

private struct TypeCommandContentView: View {
  @State var model: CommandViewModel.Kind.TypeModel
  private let onAction: (TypeCommandView.Action) -> Void
  private let debounce: DebounceManager<String>

  init(_ model: CommandViewModel.Kind.TypeModel, onAction: @escaping (TypeCommandView.Action) -> Void) {
    self.model = model
    self.onAction = onAction
    debounce = DebounceManager(for: .milliseconds(500)) { newInput in
      onAction(.updateSource(newInput: newInput))
    }
  }

  var body: some View {
    ZenTextEditor(
      color: ZenColorPublisher.shared.color,
      text: $model.input,
      placeholder: "Enter text...", onCommandReturnKey: nil)
    .onChange(of: model.input) { debounce.send($0) }
  }
}

fileprivate struct TypeCommandModeView: View {
  @State var mode: TextCommand.TypeCommand.Mode
  private let onAction: (TextCommand.TypeCommand.Mode) -> Void

  init(mode: TextCommand.TypeCommand.Mode, onAction: @escaping (TextCommand.TypeCommand.Mode) -> Void) {
    _mode = .init(initialValue: mode)
    self.onAction = onAction
  }

  var body: some View {
    Menu(content: {
      ForEach(TextCommand.TypeCommand.Mode.allCases) { mode in
        Button(action: {
          self.mode = mode
          onAction(mode)
        }, label: {
          HStack {
            Image(systemName: mode.symbol)
            Text(mode.rawValue).font(.subheadline)
          }
        })
      }
    }, label: {
      Image(systemName: mode.symbol)
      Text(mode.rawValue)
        .font(.subheadline)
    })
    .menuStyle(.regular)
    .fixedSize()
  }
}

struct TypeCommandView_Previews: PreviewProvider {
  static let command = DesignTime.typeCommand
  static var previews: some View {
    TypeCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) { _ in }
      .designTime()
      .frame(idealHeight: 120, maxHeight: 180)
  }
}

