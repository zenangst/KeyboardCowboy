import Apps
import SwiftUI

struct NewCommandApplicationView: View {
  enum ApplicationAction: String, CaseIterable {
    case open = "Open"
    case close = "Close"
  }

  @EnvironmentObject var applicationStore: ApplicationStore
  @State private var action: ApplicationAction = .open
  @State private var application: Application?
  @State private var inBackground: Bool = false
  @State private var hideWhenRunning: Bool = false
  @State private var ifNotRunning: Bool = false

  @Binding var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  @ObserveInjection var inject
  var body: some View {
    VStack(alignment: .leading) {
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
        .padding(4)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.windowBackgroundColor), lineWidth: 1)
            .frame(height: 40)
        )
        .frame(maxWidth: 80)

        Menu(content: {
          ForEach(applicationStore.applications) { app in
            Button(action: {
              application = app
              validation = updateAndValidatePayload()
            }, label: {
              Text(app.displayName)
            })
          }
        }, label: {
          if let application {
            HStack {
              Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16)
              Text(application.displayName)
            }
          } else {
            Image(nsImage: NSWorkspace.shared.icon(forFile: "/Applications"))
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16)
            Text("Select application")
          }
        })
        .padding(4)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.windowBackgroundColor), lineWidth: 1)
        )
      }
      .menuStyle(.borderlessButton)

      HStack {
        Toggle("In background", isOn: $inBackground)
        Toggle("Hide when opening", isOn: $hideWhenRunning)
        Toggle("If not running", isOn: $ifNotRunning)
      }
      .onChange(of: inBackground, perform: { _ in updateAndValidatePayload() })
      .onChange(of: hideWhenRunning, perform: { _ in updateAndValidatePayload() })
      .onChange(of: ifNotRunning, perform: { _ in updateAndValidatePayload() })
    }
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
                           hideWhenRunning: hideWhenRunning, ifNotRunning: ifNotRunning)
    return .valid
  }
}
