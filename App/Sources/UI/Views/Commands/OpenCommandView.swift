import Apps
import SwiftUI

struct OpenCommandView: View {
  enum Action {
    case updatePath(newPath: String)
    case openWith(Application)
    case commandAction(CommandContainerAction)
    case reveal(path: String)
  }
  @EnvironmentObject var applicationStore: ApplicationStore
  @Binding var command: DetailViewModel.CommandViewModel
  @State private var path: String
  @State private var isHovered = false
  @State private var notify = false
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       onAction: @escaping (Action) -> Void) {
    _command = command
    _path = .init(initialValue: command.wrappedValue.name)
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
        TextField("", text: $path)
          .textFieldStyle(AppTextFieldStyle())
          .onChange(of: path, perform: {
            onAction(.updatePath(newPath: $0))
          })
          .frame(maxWidth: .infinity)

        if case .open(_, _, let appName) = command.wrappedValue.kind {
          Menu(content: {
            ForEach(applicationStore.applicationsToOpen(command.wrappedValue.name)) { app in
              Button(app.displayName, action: {
                onAction(.openWith(app))
              })
            }
          }, label: {
              Text(appName ?? "Default")
                .font(.caption)
                .truncationMode(.middle)
                .lineLimit(1)
                .allowsTightening(true)
                .padding(4)
          })
          .menuStyle(GradientMenuStyle(.init(nsColor: .systemGray, grayscaleEffect: false),
                                       menuIndicator: applicationStore.applicationsToOpen(command.wrappedValue.name).isEmpty ? .hidden : .visible))
        }
      }
    }, subContent: { command in
      HStack {
        switch command.wrappedValue.kind {
        case .open(let path, _, _):
          if !path.hasPrefix("http") {
            Button("Reveal", action: { onAction(.reveal(path: path)) })
              .buttonStyle(GradientButtonStyle(.init(nsColor: .systemBlue, grayscaleEffect: true)))
          }
        default:
          EmptyView()
        }
      }
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
