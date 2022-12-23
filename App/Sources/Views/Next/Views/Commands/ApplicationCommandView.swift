import SwiftUI

struct ApplicationCommandView: View {
  enum Action {
    case changeApplicationModifier(modifier: ApplicationCommand.Modifier, newValue: Bool)
    case changeApplicationAction(ApplicationCommand.Action)
    case commandAction(CommandContainerAction)
  }

  @ObserveInjection var inject
  @Binding private var command: DetailViewModel.CommandViewModel

  @State private var inBackground: Bool
  @State private var hideWhenRunning: Bool
  @State private var ifNotRunning: Bool
  @State private var actionName: String

  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       actionName: String,
       inBackground: Bool,
       hideWhenRunning: Bool,
       ifNotRunning: Bool,
       onAction: @escaping (Action) -> Void) {
    _command = command
    _actionName = .init(initialValue: actionName)
    _inBackground = .init(initialValue: inBackground)
    _hideWhenRunning = .init(initialValue: hideWhenRunning)
    _ifNotRunning = .init(initialValue: ifNotRunning)
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      isEnabled: $command.isEnabled,
      icon: {
        if let image = command.image {
          Image(nsImage: image)
            .resizable()
        }
      },
      content: {
        HStack(spacing: 8) {
          Menu(content: {
            Button("Open", action: {
              actionName = "Open"
              onAction(.changeApplicationAction(.open)) })
            Button("Close", action: {
              actionName = "Close"
              onAction(.changeApplicationAction(.close)) })
          }, label: {
            HStack(spacing: 4) {
              Text(actionName)
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
          Text(command.name)
            .font(.body)
            .bold()
          Spacer()
        }
      }, subContent: {
        HStack {
          Toggle("In background", isOn: $inBackground)
            .onChange(of: inBackground) { newValue in
              onAction(.changeApplicationModifier(modifier: .background, newValue: newValue))
            }
          Toggle("Hide when opening", isOn: $hideWhenRunning)
            .onChange(of: hideWhenRunning) { newValue in
              onAction(.changeApplicationModifier(modifier: .hidden, newValue: newValue))
            }
          Toggle("If not running", isOn: $ifNotRunning)
            .onChange(of: ifNotRunning) { newValue in
              onAction(.changeApplicationModifier(modifier: .onlyIfNotRunning, newValue: newValue))
            }
        }
        .lineLimit(1)
        .allowsTightening(true)
        .truncationMode(.tail)
        .font(.caption)

      },
      onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

struct ApplicationCommandView_Previews: PreviewProvider {
  static var previews: some View {
    ApplicationCommandView(.constant(DesignTime.applicationCommand),
                           actionName: "Open",
                           inBackground: false,
                           hideWhenRunning: false,
                           ifNotRunning: false,
                           onAction: { _ in })
      .designTime()
      .frame(maxHeight: 80)
  }
}