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
      icon: { _ in SystemCommandIconView(model.kind, iconSize: iconSize)
      }, content: { _ in
        SystemCommandContentView(model: $model) { kind in
          onAction(.updateKind(newKind: kind))
        }
        .roundedContainer(padding: 4, margin: 0)
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

private struct SystemCommandIconView: View {
  let kind: SystemCommand.Kind
  let iconSize: CGSize

  init(_ kind: SystemCommand.Kind, iconSize: CGSize) {
    self.kind = kind
    self.iconSize = iconSize
  }

  var body: some View {
    switch kind {
    case .activateLastApplication:           ActivateLastApplicationIconView(size: iconSize.width)
    case .applicationWindows:                MissionControlIconView(size: iconSize.width)
    case .minimizeAllOpenWindows:            MinimizeAllIconView(size: iconSize.width)
    case .missionControl:                    MissionControlIconView(size: iconSize.width)
    case .moveFocusToNextWindow:             MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: iconSize.width)
    case .moveFocusToNextWindowFront:        MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: iconSize.width)
    case .moveFocusToNextWindowGlobal:       MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: iconSize.width)
    case .moveFocusToPreviousWindow:         MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: iconSize.width)
    case .moveFocusToPreviousWindowFront:    MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: iconSize.width)
    case .moveFocusToPreviousWindowGlobal:   MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: iconSize.width)
    case .showDesktop:                       DockIconView(size: iconSize.width)
    case .moveFocusToNextWindowUpwards:      RelativeFocusIconView(.up, size: iconSize.width)
    case .moveFocusToNextWindowDownwards:    RelativeFocusIconView(.down, size: iconSize.width)
    case .moveFocusToNextWindowOnLeft:       RelativeFocusIconView(.left, size: iconSize.width)
    case .moveFocusToNextWindowOnRight:      RelativeFocusIconView(.right, size: iconSize.width)
    case .windowTilingLeft:                  WindowTilingIcon(kind: .left, size: iconSize.width)
    case .windowTilingRight:                 WindowTilingIcon(kind: .right, size: iconSize.width)
    case .windowTilingTop:                   WindowTilingIcon(kind: .top, size: iconSize.width)
    case .windowTilingBottom:                WindowTilingIcon(kind: .bottom, size: iconSize.width)
    case .windowTilingTopLeft:               WindowTilingIcon(kind: .topLeft, size: iconSize.width)
    case .windowTilingTopRight:              WindowTilingIcon(kind: .topRight, size: iconSize.width)
    case .windowTilingBottomLeft:            WindowTilingIcon(kind: .bottomLeft, size: iconSize.width)
    case .windowTilingBottomRight:           WindowTilingIcon(kind: .bottomRight, size: iconSize.width)
    case .windowTilingCenter:                WindowTilingIcon(kind: .center, size: iconSize.width)
    case .windowTilingFill:                  WindowTilingIcon(kind: .fill, size: iconSize.width)
    case .windowTilingArrangeLeftRight:      WindowTilingIcon(kind: .arrangeLeftRight, size: iconSize.width)
    case .windowTilingArrangeRightLeft:      WindowTilingIcon(kind: .arrangeRightLeft, size: iconSize.width)
    case .windowTilingArrangeTopBottom:      WindowTilingIcon(kind: .arrangeTopBottom, size: iconSize.width)
    case .windowTilingArrangeBottomTop:      WindowTilingIcon(kind: .arrangeBottomTop, size: iconSize.width)
    case .windowTilingArrangeLeftQuarters:   WindowTilingIcon(kind: .arrangeLeftQuarters, size: iconSize.width)
    case .windowTilingArrangeRightQuarters:  WindowTilingIcon(kind: .arrangeRightQuarters, size: iconSize.width)
    case .windowTilingArrangeTopQuarters:    WindowTilingIcon(kind: .arrangeTopQuarters, size: iconSize.width)
    case .windowTilingArrangeBottomQuarters: WindowTilingIcon(kind: .arrangeBottomQuarters, size: iconSize.width)
    case .windowTilingArrangeQuarters:       WindowTilingIcon(kind: .arrangeQuarters, size: iconSize.width)
    case .windowTilingPreviousSize:          WindowTilingIcon(kind: .previousSize, size: iconSize.width)
    case .windowTilingZoom:                  WindowTilingIcon(kind: .zoom, size: iconSize.width)
    }
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
