import Apps
import SwiftUI

struct OpenCommandView: View {
  enum Action {
    case toggleNotify(newValue: Bool)
    case updateName(newName: String)
    case openWith(Application)
    case commandAction(CommandContainerAction)
    case reveal(path: String)
  }
  @EnvironmentObject var applicationStore: ApplicationStore
  @Binding var command: DetailViewModel.CommandViewModel
  @State private var name: String
  @State private var isHovered = false
  @State private var notify = false
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       onAction: @escaping (Action) -> Void) {
    _command = command
    _name = .init(initialValue: command.wrappedValue.name)
    _notify = .init(initialValue: command.wrappedValue.notify)
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($command, icon: { command in
      ZStack(alignment: .bottomTrailing) {
        if let icon = command.icon.wrappedValue {
          IconView(icon: icon, size: .init(width: 32, height: 32))

          if case .open(_, let appPath, _) = command.wrappedValue.kind,
             let appPath {
            IconView(icon: .init(bundleIdentifier: appPath, path: appPath), size: .init(width: 16, height: 16))
              .shadow(radius: 3)
          }
        }
      }
    }, content: { command in
      HStack(spacing: 2) {
        TextField("", text: $name)
          .textFieldStyle(AppTextFieldStyle())
          .onChange(of: name, perform: {
            onAction(.updateName(newName: $0))
          })
        Spacer()

        if case .open(_, _, let appName) = command.wrappedValue.kind {
          Menu(content: {
            ForEach(applicationStore.applicationsToOpen(command.wrappedValue.name)) { app in
              Button(app.displayName, action: {
                onAction(.openWith(app))
              })
            }
          }, label: {
              Text(appName ?? "Default")
                .fixedSize(horizontal: false, vertical: true)
                .truncationMode(.middle)
                .lineLimit(1)
                .allowsTightening(true)
                .padding(4)
          })
          .menuStyle(.appStyle)
          .menuIndicator(.hidden)
          .frame(maxWidth: 120)
        }
      }
    }, subContent: { command in
      HStack {
        Toggle("Notify", isOn: $notify)
          .onChange(of: notify) { newValue in
            onAction(.toggleNotify(newValue: newValue))
          }
          .lineLimit(1)
          .allowsTightening(true)
          .truncationMode(.tail)
          .font(.caption)

        Text("|")

        switch command.wrappedValue.kind {
        case .open(let path, _, _):
          Button("Reveal", action: { onAction(.reveal(path: path)) })
            .buttonStyle(GradientButtonStyle(.init(nsColor: .systemBlue)))
        default:
          EmptyView()
        }
      }
      .padding(.bottom, 4)
      .frame(maxWidth: .infinity, alignment: .leading)
      .font(.caption)
    }, onAction: { onAction(.commandAction($0)) })
    .debugEdit()
  }
}

struct OpenCommandView_Previews: PreviewProvider {
    static var previews: some View {
      OpenCommandView(.constant(DesignTime.openCommand), onAction: { _ in })
        .frame(maxHeight: 80)
    }
}
