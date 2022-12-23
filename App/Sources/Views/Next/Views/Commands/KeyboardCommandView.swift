import SwiftUI

struct KeyboardCommandView: View {
  enum Action {
    case commandAction(CommandContainerAction)
  }

  @ObserveInjection var inject
  @Binding private var command: DetailViewModel.CommandViewModel
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>, onAction: @escaping (Action) -> Void) {
    _command = command
    self.onAction = onAction
  }

  var body: some View {
    Group {
      if case .keyboard(let key, let modifiers) = command.kind {
        CommandContainerView(
          isEnabled: $command.isEnabled, icon: {
            ZStack {
              Rectangle()
                .fill(Color(nsColor: .systemGreen))
                .opacity(0.2)
                .cornerRadius(8)
              ZStack {
                RegularKeyIcon(letter: "")
                Image(systemName: "flowchart")
              }
              .scaleEffect(0.8)
            }
          }, content: {
            HStack {
              Text(command.name)
                .font(.body)
                .bold()
                .truncationMode(.head)
                .lineLimit(1)
              Spacer()
              HStack {
                ForEach(modifiers) { modifier in
                  ModifierKeyIcon(key: modifier)
                    .frame(minWidth: modifier == .command ? 48 : 32, minHeight: 32)
                    .fixedSize()
                }
                RegularKeyIcon(letter: key)
                  .fixedSize()
              }
              .padding(4)
              .background(Color(nsColor: .gridColor))
              .cornerRadius(4)
              .scaleEffect(0.85, anchor: .trailing)
              .frame(height: 32, alignment: .trailing)
            }
          },
          subContent: { },
          onAction: { onAction(.commandAction($0)) })
      } else {
        Text("Wrong kind")
      }
    }
    .enableInjection()
  }
}

struct RebindingCommandView_Previews: PreviewProvider {
  static var previews: some View {
    KeyboardCommandView(.constant(DesignTime.rebindingCommand), onAction: { _ in })
      .frame(maxHeight: 80)
  }
}