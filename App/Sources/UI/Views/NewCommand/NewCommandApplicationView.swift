import Apps
import Bonzai
import HotSwiftUI
import SwiftUI

struct NewCommandApplicationView: View {
  @ObserveInjection var inject

  enum ApplicationAction: String, CaseIterable {
    case open = "Open"
    case close = "Close"
    case hide = "Hide"
    case unhide = "Unhide"
    case peek = "Peek"
  }

  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#application-commands")!

  @EnvironmentObject var applicationStore: ApplicationStore
  @State private var action: ApplicationAction
  @State private var application: Application?
  @State private var inBackground: Bool
  @State private var hideWhenRunning: Bool
  @State private var ifNotRunning: Bool
  @State private var waitForAppToLaunch: Bool
  @State private var addToStage: Bool

  @Binding var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation

  init(_ payload: Binding<NewCommandPayload>,
       application: Application?,
       action: ApplicationAction,
       inBackground: Bool,
       hideWhenRunning: Bool,
       ifNotRunning: Bool,
       waitForAppToLaunch: Bool,
       addToStage: Bool,
       validation: Binding<NewCommandValidation>) {
    _application = .init(initialValue: application)
    _action = .init(initialValue: action)
    _payload = payload
    _validation = validation
    _inBackground = .init(initialValue: inBackground)
    _hideWhenRunning = .init(initialValue: hideWhenRunning)
    _ifNotRunning = .init(initialValue: ifNotRunning)
    _addToStage = .init(initialValue: addToStage)
    _waitForAppToLaunch = .init(initialValue: waitForAppToLaunch)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        ZenLabel("Open or Close Application:")
        Spacer()
        Button(action: { NSWorkspace.shared.open(wikiUrl) },
               label: { Image(systemName: "questionmark.circle.fill") })
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
              if app.metadata.isSafariWebApp {
                Text("\(app.displayName) (Safari Web App)")
              } else {
                Text(app.displayName)
              }
            })
          }
        }, label: {})
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
                           size: .init(width: 24, height: 24),
                         )
                         Text("Select application")
                       }
                     }
                     .padding(.leading, 8)
                     .allowsHitTesting(false)
                   })
      }

      Divider()

      Grid(alignment: .leading, verticalSpacing: 2) {
        GridRow {
          Toggle(isOn: $inBackground, label: { Text("In Background") })
            .onChange(of: inBackground, perform: { _ in updateAndValidatePayload() })
          Toggle(isOn: $hideWhenRunning, label: { Text("Hide when opening") })
            .onChange(of: hideWhenRunning, perform: { _ in updateAndValidatePayload() })
          Toggle(isOn: $ifNotRunning, label: { Text("If not running") })
            .onChange(of: ifNotRunning, perform: { _ in updateAndValidatePayload() })
        }
        GridRow {
          Toggle(isOn: $addToStage, label: { Text("Add to Stage") })
            .onChange(of: addToStage, perform: { _ in updateAndValidatePayload() })

          Toggle(isOn: $waitForAppToLaunch, label: { Text("Wait for App to Launch") })
            .onChange(of: waitForAppToLaunch, perform: { _ in updateAndValidatePayload() })

          Spacer()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .onChange(of: validation) { newValue in
        guard newValue == .needsValidation else { return }

        validation = updateAndValidatePayload()
      }
      .frame(maxHeight: 36)
    }
    .overlay(NewCommandValidationView($validation).padding(-16))
    .onAppear {
      validation = .unknown
    }
    .enableInjection()
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard let application else {
      return .invalid(reason: "Pick an application")
    }

    payload = .application(application: application, action: action,
                           inBackground: inBackground,
                           hideWhenRunning: hideWhenRunning,
                           ifNotRunning: ifNotRunning,
                           waitForAppToLaunch: waitForAppToLaunch,
                           addToStage: addToStage)
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
      onSave: { _, _ in },
    )
    .designTime()
  }
}
