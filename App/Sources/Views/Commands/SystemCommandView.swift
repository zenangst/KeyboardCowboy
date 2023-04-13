import SwiftUI

struct SystemCommandView: View {
  enum Action {
    case updateKind(newKind: SystemCommand.Kind)
    case toggleNotify(newValue: Bool)
    case commandAction(CommandContainerAction)
  }
  @State private var command: DetailViewModel.CommandViewModel
  @State private var kind: SystemCommand.Kind
  @State private var notify: Bool
  let onAction: (Action) -> Void

  init(_ command: DetailViewModel.CommandViewModel,
       kind: SystemCommand.Kind,
       onAction: @escaping (Action) -> Void) {
    _kind = .init(initialValue: kind)
    _notify = .init(initialValue: command.notify)
    _command = .init(initialValue: command)
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(command, icon: {
      ZStack {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        if let icon = command.icon {
          IconView(icon: icon, size: .init(width: 32, height: 32))
            .allowsHitTesting(false)
        }
      }
    }, content: {
      HStack(spacing: 8) {
        Menu(content: {
          ForEach(SystemCommand.Kind.allCases) { kind in
            Button(kind.displayValue) {
              self.kind = kind
              onAction(.updateKind(newKind: kind))
            }
          }
        }, label: {
          HStack(spacing: 4) {
            Text(kind.displayValue)
              .font(.caption)
              .fixedSize(horizontal: false, vertical: true)
              .truncationMode(.middle)
              .allowsTightening(true)
            Image(systemName: "chevron.down")
              .opacity(0.5)
          }
          .padding(4)
        })
        .buttonStyle(.plain)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.disabledControlTextColor))
            .opacity(0.5)
        )
      }
    }, subContent: {
      Toggle("Notify", isOn: $notify)
        .onChange(of: notify) { newValue in
          onAction(.toggleNotify(newValue: newValue))
        }
    },
    onAction: { onAction(.commandAction($0)) })
  }
}

struct SystemCommandView_Previews: PreviewProvider {
  static let kind: SystemCommand.Kind = .missionControl
  static let command = DetailViewModel.CommandViewModel(id: UUID().uuidString, name: "Test", kind: .systemCommand(kind: kind), isEnabled: true, notify: true)
  static var previews: some View {
    SystemCommandView(command, kind: kind) { _ in }
  }
}
