import Apps
import SwiftUI

struct NewCommandURLView: View {
  enum Focus: String, Identifiable, Hashable {
    var id: String { self.rawValue }
    case `protocol`
    case address
  }

  @EnvironmentObject var applicationStore: ApplicationStore
  @ObserveInjection var inject
  @FocusState var focus: Focus?

  @Binding var payload: NewCommandPayload
  @State private var stringProtocol: String = "https"
  @State private var address: String = ""
  @State private var application: Application?
  @Binding private var validation: NewCommandView.Validation

  private let onSubmitAddress: () -> Void

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandView.Validation>,
       onSubmitAddress: @escaping () -> Void) {
    _payload = payload
    _validation = validation
    self.onSubmitAddress = onSubmitAddress
  }

  var body: some View {
    VStack(alignment: .leading) {
      Label(title: { Text("Open URL:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())
      HStack(spacing: 0) {
        TextField("protocol", text: $stringProtocol)
          .frame(maxWidth: 120)
          .fixedSize(horizontal: true, vertical: false)
          .onSubmit {
            focus = .address
            updateAndValidatePayload()
          }
          .focused($focus, equals: .protocol)
        Text("://")
          .font(.largeTitle)
          .opacity(0.5)
        TextField("address", text: $address)
          .onSubmit {
            if case .valid = updateAndValidatePayload() {
              validation = .valid
              onSubmitAddress()
            } else {
              validation = .invalid
            }
          }
          .focused($focus, equals: .address)
          .padding(-2)
      }
      .onChange(of: address, perform: { newValue in
        validation = updateAndValidatePayload()
      })
      .onChange(of: validation, perform: { newValue in
        if newValue == .needsValidation {
          validation = updateAndValidatePayload()
        }
      })
      .padding(.horizontal, 2)
      .background {
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(validation == .invalid ? .systemRed.withAlphaComponent(0.5) : .windowBackgroundColor), lineWidth: 2)
          .shadow(
            color: Color(.systemRed).opacity(validation == .invalid ? 1 : 0),
            radius: 2)
      }

      HStack(spacing: 32) {
        Text("With application: ")
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
    }
    .textFieldStyle(LargeTextFieldStyle())
    .onAppear {
      validation = .unknown
      updateAndValidatePayload()
      focus = .address
    }
    .enableInjection()
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandView.Validation {
    guard !address.isEmpty,
          let url = URL(string: "\(stringProtocol)://\(address)") else {
      return .invalid
    }
    payload = .url(targetUrl: url, application: application)
    return .valid
  }
}
