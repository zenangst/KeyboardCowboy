import Bonzai
import Inject
import SwiftUI

struct SystemCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case updateKind(newKind: SystemCommand.Kind)
    case commandAction(CommandContainerAction)
  }

  @Binding var model: CommandViewModel.Kind.SystemModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.SystemModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    _model = Binding<CommandViewModel.Kind.SystemModel>(model)
    self.metaData = metaData
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { _ in SystemIconBuilder.icon(model.kind, size: iconSize.width)
      }, content: { _ in
        SystemCommandContentView(model: $model) { kind in
          onAction(.updateKind(newKind: kind))
        }
        .roundedContainer(4, padding: 4, margin: 0)
      },
      subContent: { metaData in
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
      },
      onAction: { onAction(.commandAction($0)) })
    .id(model.id)
    .enableInjection()
  }
}

private struct SystemCommandContentView: View {
  @Binding var model: CommandViewModel.Kind.SystemModel
  let onUpdate: (SystemCommand.Kind) -> Void

  init(model: Binding<CommandViewModel.Kind.SystemModel>, onUpdate: @escaping (SystemCommand.Kind) -> Void) {
    _model = model
    self.onUpdate = onUpdate
  }

  var body: some View {
    HStack(spacing: 8) {
      Menu(content: {
        ForEach(SystemCommand.Kind.allCases) { kind in
          Button(action: {
            model.kind = kind
            onUpdate(kind)
          }, label: {
            Image(systemName: kind.symbol)
            Text(kind.displayValue)
              .font(.subheadline)
          })
        }
      }, label: {
        Image(systemName: model.kind.symbol)
        Text(model.kind.displayValue)
          .font(.subheadline)
          .truncationMode(.middle)
          .allowsTightening(true)
      })
      .menuStyle(.regular)
    }
  }
}

struct SystemCommandView_Previews: PreviewProvider {
  static let command = DesignTime.systemCommand
  static var previews: some View {
    SystemCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) { _ in }
      .designTime()
  }
}
