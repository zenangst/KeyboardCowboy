import Bonzai
import SwiftUI

struct NewCommandSystemCommandView: View {
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State private var kind: SystemCommand.Kind? = nil

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      ZenLabel("System Command:")

      HStack {
        switch kind {
        case .activateLastApplication:
          ActivateLastApplicationIconView(size: 24)
        case .applicationWindows:
          MissionControlIconView(size: 24)
        case .minimizeAllOpenWindows:
          MinimizeAllIconView(size: 24)
        case .missionControl:
          MissionControlIconView(size: 24)
        case .moveFocusToNextWindow:
          MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: 24)
        case .moveFocusToNextWindowFront:
          MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: 24)
        case .moveFocusToNextWindowGlobal:
          MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: 24)
        case .moveFocusToPreviousWindow:
          MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: 24)
        case .moveFocusToPreviousWindowFront:
          MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: 24)
        case .moveFocusToPreviousWindowGlobal:
          MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: 24)
        case .showDesktop:
          DockIconView(size: 24)
        case .moveFocusToNextWindowUpwards:
          RelativeFocusIconView(.up, size: 24)
        case .moveFocusToNextWindowDownwards:
          RelativeFocusIconView(.down, size: 24)
        case .moveFocusToNextWindowOnLeft:
          RelativeFocusIconView(.left, size: 24)
        case .moveFocusToNextWindowOnRight:
          RelativeFocusIconView(.right, size: 24)
        case .windowTilingLeft:
          WindowTilingIcon(kind: .left, size: 24)
        case .windowTilingRight:
          WindowTilingIcon(kind: .right, size: 24)
        case .windowTilingTop:
          WindowTilingIcon(kind: .top, size: 24)
        case .windowTilingBottom:
          WindowTilingIcon(kind: .bottom, size: 24)
        case .windowTilingTopLeft:
          WindowTilingIcon(kind: .topLeft, size: 24)
        case .windowTilingTopRight:
          WindowTilingIcon(kind: .topRight, size: 24)
        case .windowTilingBottomLeft:
          WindowTilingIcon(kind: .bottomLeft, size: 24)
        case .windowTilingBottomRight:
          WindowTilingIcon(kind: .bottomRight, size: 24)
        case .windowTilingCenter:
          WindowTilingIcon(kind: .center, size: 24)
        case .windowTilingFill:
          WindowTilingIcon(kind: .fill, size: 24)
        case .windowTilingArrangeLeftRight:
          WindowTilingIcon(kind: .arrangeLeftRight, size: 24)
        case .windowTilingArrangeRightLeft:
          WindowTilingIcon(kind: .arrangeLeftRight, size: 24)
        case .windowTilingArrangeTopBottom:
          WindowTilingIcon(kind: .arrangeTopBottom, size: 24)
        case .windowTilingArrangeBottomTop:
          WindowTilingIcon(kind: .arrangeBottomTop, size: 24)
        case .windowTilingArrangeLeftQuarters:
          WindowTilingIcon(kind: .arrangeLeftQuarters, size: 24)
        case .windowTilingArrangeRightQuarters:
          WindowTilingIcon(kind: .arrangeRightQuarters, size: 24)
        case .windowTilingArrangeTopQuarters:
          WindowTilingIcon(kind: .arrangeTopQuarters, size: 24)
        case .windowTilingArrangeBottomQuarters:
          WindowTilingIcon(kind: .arrangeBottomQuarters, size: 24)
        case .windowTilingArrangeQuarters:
          WindowTilingIcon(kind: .arrangeQuarters, size: 24)
        case .windowTilingPreviousSize:
          WindowTilingIcon(kind: .previousSize, size: 24)
        case .windowTilingZoom:
          WindowTilingIcon(kind: .zoom, size: 24)
        case .none:
          EmptyView()
        }
        Menu {
          ForEach(SystemCommand.Kind.allCases) { kind in
            Button {
              self.kind = kind
              validation = updateAndValidatePayload()
            } label: {
              Image(systemName: kind.symbol)
              Text(kind.displayValue)
            }
          }
        } label: {
          if let kind {
            Image(systemName: kind.symbol)
            Text(kind.displayValue)
          } else {
            Text("Select system command")
          }
        }
      }
      .background(NewCommandValidationView($validation))
    }
    .menuStyle(.regular)
    .onChange(of: validation, perform: { newValue in
      guard newValue == .needsValidation else { return }
      withAnimation { validation = updateAndValidatePayload() }
    })
    .onAppear {
      validation = .unknown
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard let kind else { return .invalid(reason: "Pick a system command.") }

    payload = .systemCommand(kind: kind)

    return .valid
  }
}

struct NewCommandSystemCommandView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .system,
      payload: .systemCommand(kind: .applicationWindows),
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
