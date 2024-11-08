import Bonzai
import Inject
import SwiftUI

struct TypeCommandView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  private let metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.TypeModel
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.TypeModel,
       iconSize: CGSize) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { metaData in
        TypingIconView(size: iconSize.width)
      }, content: { _ in
        TypeCommandContentView(metaData: metaData, model: model)
          .roundedContainer(4, padding: 0, margin: 0)
      }, subContent: { metaData in
        HStack {
          ZenCheckbox("Notify", style: .small, isOn: Binding(get: {
            if case .bezel = metaData.notification.wrappedValue { return true } else { return false }
          }, set: { newValue in
            metaData.notification.wrappedValue = newValue ? .bezel : nil
            updater.modifyCommand(withID: metaData.id, using: transaction) { command in
              command.notification = newValue ? .bezel : nil
            }
          })) { value in
            updater.modifyCommand(withID: metaData.id, using: transaction) { command in
              command.notification = value ? .bezel : nil
            }
          }
          .offset(x: 1)

          Spacer()

          TypeCommandModeView(mode: model.mode) { newMode in
            updater.modifyCommand(withID: metaData.id, using: transaction) { command in
              guard case .text(let textCommand) = command else { return }
              switch textCommand.kind {
              case .insertText(var typeCommand):
                typeCommand.mode = newMode
                command = .text(.init(.insertText(typeCommand)))
              }
            }
          }
        }
      })
    .enableInjection()
  }
}

private struct TypeCommandContentView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  let metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.TypeModel

  init(metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.TypeModel) {
    self.metaData = metaData
    self.model = model
  }

  var body: some View {
    ZenTextEditor(
      color: ZenColorPublisher.shared.color,
      text: $model.input,
      placeholder: "Enter text...", onCommandReturnKey: nil)
    .onChange(of: model.input) { newValue in
      updater.modifyCommand(withID: metaData.id, using: transaction) { command in
        guard case .text(let textCommand) = command else { return }
        switch textCommand.kind {
        case .insertText(var typeCommand):
          typeCommand.input = newValue
          command = .text(.init(.insertText(typeCommand)))
        }
      }
    }
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
    TypeCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) 
      .designTime()
      .frame(idealHeight: 120, maxHeight: 180)
  }
}

