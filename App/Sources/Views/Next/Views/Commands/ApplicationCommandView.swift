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

  @ObserveInjection var inject
  @Binding private var command: DetailViewModel.CommandViewModel

  @EnvironmentObject var applicationStore: ApplicationStore

  @State private var name: String
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
    _name = .init(initialValue: command.name.wrappedValue)
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
          ZStack {
            Menu(content: {
              ForEach(applicationStore.applications) { app in
                Button(action: {
                  onAction(.changeApplication(app))
                  command.image = NSWorkspace.shared.icon(forFile: app.path)
                }, label: {
                  Text(app.displayName)
                })
              }
            }, label: { })
            .menuStyle(IconMenuStyle())
            .menuIndicator(.hidden)

            Image(nsImage: image)
              .resizable()
              .allowsHitTesting(false)
          }
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
