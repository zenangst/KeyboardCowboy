import Apps
import Bonzai
import Inject
import SwiftUI

struct NewCommandURLView: View {
  @ObserveInjection var inject
  enum Focus: String, Identifiable, Hashable {
    var id: String { rawValue }
    case `protocol`
    case address
  }

  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#url-commands")!

  @EnvironmentObject var applicationStore: ApplicationStore
  @FocusState var focus: Focus?

  @Binding var payload: NewCommandPayload
  @State private var stringProtocol: String = "https"
  @State private var address: String = ""
  @State private var application: Application?
  @Binding private var validation: NewCommandValidation

  private let onSubmitAddress: () -> Void

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandValidation>,
       onSubmitAddress: @escaping () -> Void)
  {
    _payload = payload
    _validation = validation
    self.onSubmitAddress = onSubmitAddress
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ZenLabel("Open URL:")
        Spacer()
        Button(action: { NSWorkspace.shared.open(wikiUrl) },
               label: { Image(systemName: "questionmark.circle.fill") })
      }
      HStack(spacing: 8) {
        TextField("protocol", text: $stringProtocol)
          .frame(maxWidth: 120)
          .fixedSize(horizontal: true, vertical: false)
          .onSubmit {
            focus = .address
            updateAndValidatePayload()
          }
          .focused($focus, equals: .protocol)
        Text("://")
          .font(.title)
          .opacity(0.5)
        TextField("address", text: $address)
          .onSubmit {
            if case .valid = updateAndValidatePayload() {
              validation = .valid
              onSubmitAddress()
            } else {
              withAnimation { validation = .invalid(reason: "Invalid address") }
            }
          }
          .focused($focus, equals: .address)
          .padding(-2)
      }
      .environment(\.textFieldFont, .title)
      .background(Color(nsColor: .windowBackgroundColor))
      .onChange(of: address, perform: { newValue in
        if let components = URLComponents(string: newValue),
           let host = components.host,
           let scheme = components.scheme
        {
          stringProtocol = scheme

          var newString = host + components.path

          if let query = components.query {
            newString += "?" + query
          }

          address <- newString
        }

        validation = updateAndValidatePayload()
      })
      .onChange(of: validation, perform: { newValue in
        guard newValue == .needsValidation else { return }

        validation = updateAndValidatePayload()
      })
      .padding(.horizontal, 2)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(validation.isInvalid ? .systemRed : .white.withAlphaComponent(0.2)), lineWidth: 1),
      )
      .overlay(NewCommandValidationView($validation))
      .zIndex(2)

      ZenDivider()

      HStack(spacing: 32) {
        Text("With Application: ")
        Menu(content: {
          ForEach(applicationStore.applications) { app in
            Button(action: {
              application = app
              updateAndValidatePayload()
            }, label: {
              Text(app.displayName)
            })
          }
        }, label: {
          if let application {
            Text(application.displayName)
          } else {
            Text("Default application")
          }
        })
      }
      .zIndex(1)
    }
    .onAppear {
      validation = .unknown
      updateAndValidatePayload()
      focus = .address
    }
    .enableInjection()
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard !address.isEmpty,
          let url = URL(string: "\(stringProtocol)://\(address)")
    else {
      return .invalid(reason: "Not a valid URL")
    }

    payload = .url(targetUrl: url, application: application)
    return .valid
  }
}

struct NewCommandURLView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .url,
      payload: .url(targetUrl: URL(filePath: "~/"), application: nil),
      onDismiss: {},
      onSave: { _, _ in },
    )
    .designTime()
  }
}
