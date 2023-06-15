import Apps
import SwiftUI

struct NewCommandApplicationView: View {
  enum ApplicationAction: String, CaseIterable {
    case open = "Open"
    case close = "Close"
  }

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
      Label(title: { Text("Open or Close Application:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())

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
        .menuStyle(GradientMenuStyle(.init(nsColor: .systemGray, padding: .init(horizontal: 8, vertical: 7)), fixedSize: false))
        .frame(maxWidth: 80)

        Menu(content: {
          ForEach(applicationStore.applications) { app in
            Button(action: {
              application = app
              validation = updateAndValidatePayload()
            }, label: {
              Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
              Text(app.displayName)
            })
          }
        }, label: { })
        .overlay(alignment: .leading, content: {
          HStack {
            if let application {
              Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
              Text(application.displayName)
            } else {
              Image(nsImage: NSWorkspace.shared.icon(forFile: "/Applications"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
              Text("Select application")
            }
          }
          .padding(.leading, 8)
          .allowsHitTesting(false)
        })
      }
      .menuStyle(GradientMenuStyle(.init(nsColor: .systemGray, padding: .init(horizontal: 8, vertical: 8)), fixedSize: false))

      Divider()

      HStack {
        Toggle("In background", isOn: $inBackground)
        Toggle("Hide when opening", isOn: $hideWhenRunning)
        Toggle("If not running", isOn: $ifNotRunning)
      }
      .onChange(of: inBackground, perform: { _ in updateAndValidatePayload() })
      .onChange(of: hideWhenRunning, perform: { _ in updateAndValidatePayload() })
      .onChange(of: ifNotRunning, perform: { _ in updateAndValidatePayload() })
      .onChange(of: validation) { newValue in
        guard newValue == .needsValidation else { return }
        validation = updateAndValidatePayload()
      }
    }
    .menuStyle(.appStyle(padding: 4))
    .overlay(NewCommandValidationView($validation).padding(-8))
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
