import Bonzai
import Inject
import SwiftUI

struct SystemCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case updateKind(newKind: SystemCommand.Kind)
    case commandAction(CommandContainerAction)
  }
  @State var metaData: CommandViewModel.MetaData
  @Binding var model: CommandViewModel.Kind.SystemModel
  private let iconSize: CGSize
  let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.SystemModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = Binding<CommandViewModel.Kind.SystemModel>(model)
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData, placeholder: model.placeholder, icon: { command in
      switch model.kind {
      case .activateLastApplication:
        EmptyView()
      case .applicationWindows:
        MissionControlIconView(size: iconSize.width - 6)
      case .minimizeAllOpenWindows:
        EmptyView()
      case .missionControl:
        MissionControlIconView(size: iconSize.width - 6)
      case .moveFocusToNextWindow:
        MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: iconSize.width - 6)
      case .moveFocusToNextWindowFront:
        MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: iconSize.width - 6)
      case .moveFocusToNextWindowGlobal:
        MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: iconSize.width - 6)
      case .moveFocusToPreviousWindow:
        MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: iconSize.width - 6)
      case .moveFocusToPreviousWindowFront:
        MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: iconSize.width - 6)
      case .moveFocusToPreviousWindowGlobal:
        MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: iconSize.width - 6)
      case .showDesktop:
        DockIconView(size: iconSize.width - 6)
      }
    }, content: { command in
      HStack(spacing: 8) {
        Menu(content: {
          ForEach(SystemCommand.Kind.allCases) { kind in
            Button(action: {
              model.kind = kind
              onAction(.updateKind(newKind: kind))
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
    }, subContent: { _ in },
    onAction: { onAction(.commandAction($0)) })
    .id(model.id)
    .enableInjection()
  }
}


struct SystemCommandView_Previews: PreviewProvider {
  static let command = DesignTime.systemCommand
  static var previews: some View {
    SystemCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) { _ in }
      .designTime()
  }
}
