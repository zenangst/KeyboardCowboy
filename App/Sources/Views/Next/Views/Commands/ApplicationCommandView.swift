import SwiftUI

struct ApplicationCommandView: View {
  enum Action {
    case changeConfiguration(ApplicationModifier)
    case commandAction(CommandContainerAction)
  }

  enum ApplicationModifier: String, Identifiable {
    var id: String { rawValue }
    case open = "Open"
    case close = "Close"
  }

  enum ApplicationConfiguration: String, Identifiable {
    var id: String { rawValue }
    case inBackground = "In background"
    case hideWhenOpening = "Hide when opening"
    case ifNotRunning = "If not running"
  }

  @ObserveInjection var inject
  @Binding private var command: DetailViewModel.CommandViewModel
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       onAction: @escaping (Action) -> Void) {
    _command = command
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
            Button("Open", action: { onAction(.changeConfiguration(.open)) })
            Button("Close", action: { onAction(.changeConfiguration(.close)) })
          }, label: {
            HStack(spacing: 4) {
              Text("Open")
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
          Toggle("In background", isOn: .constant(false))
          Toggle("Hide when opening", isOn: .constant(false))
          Toggle("If not running", isOn: .constant(false))
        }
        .lineLimit(1)
        .allowsTightening(true)
        .truncationMode(.tail)
        .font(.caption)

      }, onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

struct ApplicationCommandView_Previews: PreviewProvider {
  static var previews: some View {
    ApplicationCommandView(.constant(DesignTime.applicationCommand), onAction: { _ in })
      .designTime()
      .frame(maxHeight: 80)
  }
}
