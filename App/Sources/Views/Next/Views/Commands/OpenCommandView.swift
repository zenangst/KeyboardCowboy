import Apps
import SwiftUI

struct OpenCommandView: View {
  enum Action {
    case updateName(newName: String)
    case openWith(Application)
    case commandAction(CommandContainerAction)
    case reveal(path: String)
  }
  @ObserveInjection var inject
  @EnvironmentObject var applicationStore: ApplicationStore
  @Binding var command: DetailViewModel.CommandViewModel
  @State private var name: String
  @State private var isHovered = false
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       onAction: @escaping (Action) -> Void) {
    _command = command
    _name = .init(initialValue: command.wrappedValue.name)
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
        TextField("", text: $name)
          .textFieldStyle(AppTextFieldStyle())
          .onChange(of: name, perform: {
            onAction(.updateName(newName: $0))
          })
        Spacer()

        if case .open(_, let appName) = command.kind,
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
        switch command.kind {
        case .open(let path, _):
          Button("Reveal", action: { onAction(.reveal(path: path)) })
        default:
          EmptyView()
        }
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
