import Apps
import SwiftUI

struct OpenCommandView: View {
  enum Action {
    case openWith(Application)
    case commandAction(CommandContainerAction)
    case reveal
  }
  @ObserveInjection var inject
  @EnvironmentObject var applicationStore: ApplicationStore
  @Binding var command: DetailViewModel.CommandViewModel
  @State private var isHovered = false
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       onAction: @escaping (Action) -> Void) {
    _command = command
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(isEnabled: $command.isEnabled, icon: {
      if let image = command.image {
        Image(nsImage: image)
          .resizable()
      }
    }, content: {

      HStack(spacing: 2) {
        TextField("", text: $command.name)
          .font(.system(.body, design: .rounded, weight: .semibold))
          .truncationMode(.head)
          .textFieldStyle(.plain)
          .minimumScaleFactor(0.5)
          .lineLimit(1)
          .padding(6)
          .background(
            RoundedRectangle(cornerRadius: 4)
              .stroke(isHovered ? Color(nsColor: .controlAccentColor) : .clear, lineWidth: 1)
              .animation(.default, value: isHovered)
          )
          .onHover { hovering in
            self.isHovered = hovering
          }
        Spacer()

        if case .open(let appName) = command.kind,
           let appName {
          Menu(content: {
            ForEach(applicationStore.applicationsToOpen(command.name)) { app in
              Button(app.displayName, action: {
                onAction(.openWith(app))
              })
            }
          }, label: {
            HStack(spacing: 4) {
              Text(appName)
                .fixedSize(horizontal: false, vertical: true)
                .truncationMode(.middle)
                .lineLimit(1)
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
      }
    }, subContent: {
      HStack {
        Button("Reveal", action: { onAction(.reveal) })
      }
      .padding(.bottom, 4)
      .font(.caption)
    }, onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

struct OpenCommandView_Previews: PreviewProvider {
    static var previews: some View {
      OpenCommandView(.constant(DesignTime.openCommand), onAction: { _ in })
        .frame(maxHeight: 80)
    }
}
