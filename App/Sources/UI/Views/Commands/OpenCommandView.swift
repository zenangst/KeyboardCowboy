import Apps
import SwiftUI

struct OpenCommandView: View {
  enum Action {
    case updatePath(newPath: String)
    case openWith(Application?)
    case commandAction(CommandContainerAction)
    case reveal(path: String)
  }
  @State var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.OpenModel
  private let debounce: DebounceManager<String>
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.OpenModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.debounce = DebounceManager(for: .milliseconds(500)) { newPath in
      onAction(.updatePath(newPath: newPath))
    }
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData, icon: { command in
      ZStack(alignment: .bottomTrailing) {
        if let icon = command.icon.wrappedValue {
          IconView(icon: icon, size: .init(width: 32, height: 32))
          if let appPath = model.applicationPath {
            IconView(icon: .init(bundleIdentifier: appPath, path: appPath), size: .init(width: 16, height: 16))
              .shadow(radius: 3)
          }
        }
      }
    }, content: { command in
      HStack(spacing: 2) {
        TextField("", text: $model.path)
          .textFieldStyle(AppTextFieldStyle())
          .onChange(of: model.path, perform: { debounce.send($0) })
          .frame(maxWidth: .infinity)

        if !model.applications.isEmpty {
          Menu(content: {
            ForEach(model.applications) { app in
              Button(app.displayName, action: {
                model.appName = app.displayName
                model.applicationPath = app.path
                onAction(.openWith(app))
              })
            }
            Divider()
            Button("Default", action: {
              model.appName = nil
              model.applicationPath = nil
              onAction(.openWith(nil))
            })
          }, label: {
            Text(model.appName ?? "Default")
              .font(.caption)
              .truncationMode(.middle)
              .lineLimit(1)
              .allowsTightening(true)
              .padding(4)
          })
          .menuStyle(GradientMenuStyle(.init(nsColor: .systemGray, grayscaleEffect: false),
                                       menuIndicator: model.applications.isEmpty ? .hidden : .visible))
        }
      }
    }, subContent: { command in
      HStack {
        if model.path.hasPrefix("http") == false {
          Button("Reveal", action: { onAction(.reveal(path: model.path)) })
            .buttonStyle(GradientButtonStyle(.init(nsColor: .systemBlue, grayscaleEffect: true)))
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .font(.caption)
    }, onAction: { onAction(.commandAction($0)) })
    .debugEdit()
  }
}

struct OpenCommandView_Previews: PreviewProvider {
  static let command = DesignTime.openCommand
  static var previews: some View {
    OpenCommandView(command.model.meta, model: command.kind) { _ in }
      .designTime()
      .frame(maxHeight: 80)
  }
}
