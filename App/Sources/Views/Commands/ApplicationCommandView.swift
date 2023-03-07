import Apps
import SwiftUI

struct IconMenuStyle: MenuStyle {
  func makeBody(configuration: Configuration) -> some View {
    Menu(configuration)
      .menuStyle(.borderlessButton)
      .mask(
        GeometryReader { proxy in
          if proxy.size.width > 2 && proxy.size.height > 2 {
            RoundedRectangle(cornerRadius: 8)
              .frame(width: proxy.size.width - 2, height: proxy.size.height - 2)
              .offset(x: -1)
          } else {
            EmptyView()
          }
        }
      )
  }
}

struct ApplicationCommandView: View {
  enum Action {
    case changeApplication(Application)
    case updateName(newName: String)
    case changeApplicationModifier(modifier: ApplicationCommand.Modifier, newValue: Bool)
    case changeApplicationAction(ApplicationCommand.Action)
    case commandAction(CommandContainerAction)
  }

  @State private var command: DetailViewModel.CommandViewModel

  @EnvironmentObject var applicationStore: ApplicationStore

  @State private var name: String
  @State private var inBackground: Bool
  @State private var hideWhenRunning: Bool
  @State private var ifNotRunning: Bool
  @State private var actionName: String

  private let onAction: (Action) -> Void

  init(_ command: DetailViewModel.CommandViewModel,
       actionName: String,
       inBackground: Bool,
       hideWhenRunning: Bool,
       ifNotRunning: Bool,
       onAction: @escaping (Action) -> Void) {
    _command = .init(initialValue: command)
    _name = .init(initialValue: command.name)
    _actionName = .init(initialValue: actionName)
    _inBackground = .init(initialValue: inBackground)
    _hideWhenRunning = .init(initialValue: hideWhenRunning)
    _ifNotRunning = .init(initialValue: ifNotRunning)
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      command,
      icon: {
        if let icon = command.icon {
          ApplicationCommandImageView($command, icon: icon, onAction: onAction)
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
          TextField("", text: $name)
            .textFieldStyle(AppTextFieldStyle())
            .onChange(of: name, perform: {
              onAction(.updateName(newName: $0))
            })
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
    .debugEdit()
  }
}

struct ApplicationCommandImageView: View {
  @EnvironmentObject var applicationStore: ApplicationStore
  @State var isHovered: Bool = false
  @Binding private var command: DetailViewModel.CommandViewModel
  private let icon: IconViewModel
  private let onAction: (ApplicationCommandView.Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       icon: IconViewModel,
       onAction: @escaping (ApplicationCommandView.Action) -> Void) {
    _command = command
    self.icon = icon
    self.onAction = onAction
  }

  var body: some View {
    // TODO: Fix flickering bug when dragging an application command.
    ZStack {
      Menu(content: {
        ForEach(applicationStore.applications) { app in
          Button(action: {
            onAction(.changeApplication(app))
            command.icon = .init(bundleIdentifier: app.bundleIdentifier, path: app.path)
          }, label: {
            Text(app.displayName)
          })
        }
      }, label: { })
      .menuStyle(IconMenuStyle())
      .menuIndicator(.hidden)

      IconView(icon: icon, size: .init(width: 32, height: 32))
    }
  }
}

struct ApplicationCommandView_Previews: PreviewProvider {
  static var previews: some View {
    ApplicationCommandView(DesignTime.applicationCommand,
                           actionName: "Open",
                           inBackground: false,
                           hideWhenRunning: false,
                           ifNotRunning: false,
                           onAction: { _ in })
      .designTime()
      .frame(maxHeight: 80)
  }
}
