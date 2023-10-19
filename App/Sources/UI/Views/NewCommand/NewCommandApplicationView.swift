import Apps
import SwiftUI
import Bonzai

struct NewCommandApplicationView: View {
  enum ApplicationAction: String, CaseIterable {
    case open = "Open"
    case close = "Close"
  }

  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#application-commands")!

  @EnvironmentObject var applicationStore: ApplicationStore
  @State private var action: ApplicationAction
  @State private var application: Application?
  @State private var inBackground: Bool
  @State private var hideWhenRunning: Bool
  @State private var ifNotRunning: Bool

  @Binding var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation

  init(_ payload: Binding<NewCommandPayload>,
       application: Application?,
       action: ApplicationAction,
       inBackground: Bool,
       hideWhenRunning: Bool,
       ifNotRunning: Bool,
       validation: Binding<NewCommandValidation>) {
    _application = .init(initialValue: application)
    _action = .init(initialValue: action)
    _payload = payload
    _validation = validation
    _inBackground = .init(initialValue: inBackground)
    _hideWhenRunning = .init(initialValue: hideWhenRunning)
    _ifNotRunning = .init(initialValue: ifNotRunning)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Label(title: { Text("Open or Close Application:") }, icon: { EmptyView() })
          .labelStyle(HeaderLabelStyle())
        Spacer()
        Button(action: { NSWorkspace.shared.open(wikiUrl) },
               label: { Image(systemName: "questionmark.circle.fill") })
        .buttonStyle(.calm(color: .systemYellow, padding: .small))
      }

      HStack {
        Menu(content: {
          ForEach(ApplicationAction.allCases, id: \.rawValue) { action in
            Button(action.rawValue, action: {
              self.action = action
              updateAndValidatePayload()
            })
          }
        }, label: {
          Text(action.rawValue)
        })
        .frame(maxWidth: 80)

        Menu(content: {
          ForEach(applicationStore.applications, id: \.path) { app in
            Button(action: {
              application = app
              validation = updateAndValidatePayload()
            }, label: {
              Text(app.displayName)
            })
          }
        }, label: { })
        .overlay(alignment: .leading,
                 content: {
          HStack {
            if let application {
              IconView(icon: .init(application), size: .init(width: 24, height: 24))
              Text(application.displayName)
            } else {
              IconView(
                icon: .init(bundleIdentifier: "/System/Applications/Utilities/Script Editor.app",
                           path: "/System/Applications/Utilities/Script Editor.app"),
                size: .init(width: 24, height: 24)
              )
              Text("Select application")
            }
          }
          .padding(.leading, 8)
          .allowsHitTesting(false)
        })
      }

      .menuStyle(.zen(.init(color: .systemGray, 
                            padding: .init(horizontal: .large, vertical: .large))))

      Divider()

      HStack {
        ZenCheckbox("In background", style: .small, isOn: $inBackground) { _ in
         updateAndValidatePayload()
        }
        ZenCheckbox("Hide when opening", style: .small, isOn: $hideWhenRunning) { _ in
          updateAndValidatePayload()
         }
        ZenCheckbox("If not running", style: .small, isOn: $ifNotRunning) { _ in
          updateAndValidatePayload()
         }
      }
      .onChange(of: validation) { newValue in
        guard newValue == .needsValidation else { return }
        validation = updateAndValidatePayload()
      }
    }
    .overlay(NewCommandValidationView($validation).padding(-16))
    .onAppear {
      validation = .unknown
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard let application else {
      return .invalid(reason: "Pick an application")
    }
    payload = .application(application: application, action: action,
                           inBackground: inBackground,
                           hideWhenRunning: hideWhenRunning, ifNotRunning: ifNotRunning)
    return .valid
  }
}

struct NewCommandApplicationView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .application,
      payload: .placeholder,
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
