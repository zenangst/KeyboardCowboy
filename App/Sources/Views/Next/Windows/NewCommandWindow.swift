import Apps
import Carbon
import SwiftUI

enum NewCommandPayload {
  case url(targetUrl: URL, application: Application?)
}

struct NewCommandWindow: Scene {
  enum Context: Identifiable, Hashable, Codable {
    var id: String {
      switch self {
      case .newCommand(let workflowId):
        return workflowId
      }
    }

    case newCommand(workflowId: Workflow.ID)
  }

  private let onSave: (Workflow.ID, NewCommandPayload) -> Void
  private let contentStore: ContentStore

  init(contentStore: ContentStore, onSave: @escaping (Workflow.ID, NewCommandPayload) -> Void) {
    self.contentStore = contentStore
    self.onSave = onSave
  }

  var body: some Scene {
    WindowGroup(for: Context.self) { $context in
      switch context {
      case .newCommand(let workflowId):
        NewCommandView(workflowId: workflowId) { payload in
          onSave(workflowId, payload)
          KeyboardCowboy.keyWindow?.close()
          KeyboardCowboy.mainWindow?.makeKey()
        }
        .frame(minWidth: 400, maxWidth: 600, minHeight: 300, maxHeight: 500)
        .environmentObject(contentStore.applicationStore)
        .ignoresSafeArea(edges: .all)
      case .none:
        EmptyView()
      }
    }
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)
    .defaultPosition(.topTrailing)
  }
}

struct NewCommandView: View {
  enum Kind: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case application = "Application"
    case url = "URL"
    case open = "Open"
  }

  @ObserveInjection var inject
  let workflowId: Workflow.ID

  @Environment(\.controlActiveState) var controlActiveState
  @State private var payload: NewCommandPayload = .url(targetUrl: URL(fileURLWithPath: "/"),
                                                       application: nil)
  @State private var selection: Kind = .url
  private let onSave: (NewCommandPayload) -> Void
  @FocusState var focused: Kind?

  init(workflowId: Workflow.ID, onSave: @escaping (NewCommandPayload) -> Void) {
    self.workflowId = workflowId
    self.onSave = onSave
  }

  var body: some View {
    VStack(alignment: .leading) {
      VStack {
        Text("New command")
          .allowsTightening(true)
          .opacity(controlActiveState == .key ? 1 : 0.6)
        ScrollView(.horizontal) {
          HStack {
            ForEach(Kind.allCases) { kind in
              NewCommandButtonView(content: {
                Text(kind.rawValue)
                  .padding(16)
              }, onKeyDown: { keyCode, _ in
                if keyCode == kVK_Return {
                  selection = kind
                  focused = nil
                }
              }) {
                selection = kind
                focused = nil
              }
              .background(
                GeometryReader { proxy in
                  Path { path in
                    path.move(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
                    path.addLine(to: CGPoint(x: proxy.size.width / 2 - 16, y: proxy.size.height))
                    path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height + 8))
                    path.addLine(to: CGPoint(x: proxy.size.width / 2 + 16, y: proxy.size.height))
                  }
                  .fill(Color(.textBackgroundColor))
                  .shadow(radius: 2, y: 4)
                  .opacity(selection == kind ? 1 : 0)
                }
              )
              .focusable()
              .focused($focused, equals: .application)
              .padding()
            }
          }
        }
        .padding(.bottom, -16)
      }
      .padding(.top, 4)
      .background(alignment: .bottom, content: {
        Rectangle()
          .fill(Color(.textBackgroundColor))
          .shadow(radius: 2, y: 3)
      })

      Group {
        switch selection {
        case .application:
          NewCommandApplicationView()
        case .url:
          NewCommandURLView($payload, onSubmitAddress: {
            onSave(payload)
          })
        case .open:
          NewCommandOpenView()
        }
      }
      .padding()

      Spacer()
      HStack {
        Spacer()
        Button(action: {
          onSave(payload)
        }, label: {
          Text("Save")
        })
      }
      .buttonStyle(.appStyle)
      .padding()
    }
    .enableInjection()
  }
}

struct NewCommandApplicationView: View {
  var body: some View {
    Text("Application")
  }
}

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

  private let onSubmitAddress: () -> Void

  init(_ payload: Binding<NewCommandPayload>, onSubmitAddress: @escaping () -> Void) {
    _payload = payload
    self.onSubmitAddress = onSubmitAddress
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("Open URL:")
      HStack(spacing: 0) {
        TextField("protocol", text: $stringProtocol)
          .frame(maxWidth: 120)
          .fixedSize(horizontal: true, vertical: false)
          .onSubmit {
            focus = .address
            updatePayload()
          }
          .focused($focus, equals: .protocol)
        Text("://")
          .font(.largeTitle)
          .opacity(0.5)
        TextField("address", text: $address)
          .onSubmit {
            updatePayload()
            onSubmitAddress()
          }
          .focused($focus, equals: .address)
      }
      .background {
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(.windowBackgroundColor), lineWidth: 2)
      }

      HStack {
        Text("With application: ")
        Menu(content: {
          ForEach(applicationStore.applications) { app in
            Button(action: {
              application = app
              updatePayload()
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
      focus = .address
    }
    .enableInjection()
  }

  private func updatePayload() {
    guard let url = URL(string: "\(stringProtocol)://\(address)") else {
      return
    }
    payload = .url(targetUrl: url, application: application)
  }
}

struct NewCommandOpenView: View {
  var body: some View {
    Text("Open")
  }
}

struct NewCommandButtonView<Content>: View where Content: View {
  @FocusState private var isFocused: Bool
  @ObserveInjection var inject

  private let content: () -> Content
  private let action: () -> Void
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(content: @escaping () -> Content, onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void, action: @escaping () -> Void) {
    self.content = content
    self.action = action
    self.onKeyDown = onKeyDown
  }

  var body: some View {
    Button(action: action) {
      content()
        .foregroundColor(isFocused ? Color(.controlAccentColor) : Color(.textColor))
        .shadow(color: Color(.controlAccentColor).opacity(isFocused ? 0.5 : 0), radius: 4)
    }
    .background {
      ZStack {
        FocusableProxy(id: UUID().uuidString, onKeyDown: onKeyDown)
      }
    }
    .buttonStyle(.plain)
    .focusable()
    .focused($isFocused)
    .enableInjection()
  }
}
