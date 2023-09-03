import SwiftUI

struct SystemCommandView: View {
  enum Action {
    case updateKind(newKind: SystemCommand.Kind)
    case commandAction(CommandContainerAction)
  }
  @Binding var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.SystemModel
  let onAction: (Action) -> Void

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       model: CommandViewModel.Kind.SystemModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = metaData
    _model = .init(initialValue: model)
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData, icon: { command in
      ZStack {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        IconView(icon: model.kind.icon, size: .init(width: 32, height: 32))
          .allowsHitTesting(false)
      }
    }, content: { command in
      HStack(spacing: 8) {
        Menu(content: {
          ForEach(SystemCommand.Kind.allCases) { kind in
            Button(kind.displayValue) {
              model.kind = kind
              onAction(.updateKind(newKind: kind))
            }
          }
        }, label: {
          HStack(spacing: 4) {
            Text(model.kind.displayValue)
              .font(.caption)
              .truncationMode(.middle)
              .allowsTightening(true)
          }
          .padding(4)
        })
        .menuStyle(AppMenuStyle(.init(nsColor: .systemGray, grayscaleEffect: false), fixedSize: false))
      }
    }, subContent: { _ in },
    onAction: { onAction(.commandAction($0)) })
    .id(model.id)
  }
}

extension SystemCommand.Kind {
  var icon: IconViewModel {
    let path: String
    switch self {
    case .applicationWindows:
      path = "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
    case .moveFocusToNextWindowFront:
      path = "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
    case .moveFocusToPreviousWindowFront:
      path = "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
    case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal:
      path = "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
    case .moveFocusToPreviousWindow, .moveFocusToPreviousWindowGlobal:
      path = "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
    case .missionControl:
      path = "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
    case .showDesktop:
      path = "/System/Library/CoreServices/Dock.app/Contents/Resources/Dock.icns"
    }
    return IconViewModel(bundleIdentifier: path, path: path)
  }
}

struct SystemCommandView_Previews: PreviewProvider {
  static let command = DesignTime.systemCommand
  static var previews: some View {
    SystemCommandView(.constant(command.model.meta), model: command.kind) { _ in }
      .designTime()
  }
}
