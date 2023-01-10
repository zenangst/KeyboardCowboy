import Apps
import Carbon
import SwiftUI

enum NewCommandPayload {
  case url(targetUrl: URL, application: Application?)
  case open(path: String, application: Application?)
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
        .frame(minWidth: 500, maxWidth: 650, minHeight: 400, maxHeight: 500)
        .environmentObject(contentStore.applicationStore)
        .environmentObject(OpenPanelController())
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
    var rawKey: String {
      switch self {
      case .application:
        return "1"
      case .url:
        return "2"
      case .open:
        return "3"
      }
    }
    var key: KeyEquivalent {
      return KeyEquivalent(rawKey.first!)
    }

    case application = "Application"
    case url = "URL"
    case open = "Open"
  }

  @ObserveInjection var inject
  let workflowId: Workflow.ID

  @Environment(\.controlActiveState) var controlActiveState
  @State private var payload: NewCommandPayload = .url(targetUrl: URL(fileURLWithPath: "/"),
                                                       application: nil)
  @State private var selection: Kind = .open
  private let onSave: (NewCommandPayload) -> Void
  @FocusState var focused: Kind?

  init(workflowId: Workflow.ID, onSave: @escaping (NewCommandPayload) -> Void) {
    self.workflowId = workflowId
    self.onSave = onSave
  }

  var body: some View {
    VStack(alignment: .leading) {
      VStack(spacing: 0) {
        Text("New command")
          .font(.system(.body, design: .rounded,weight: .semibold))
          .allowsTightening(true)
          .opacity(controlActiveState == .key ? 1 : 0.6)
        ScrollView(.horizontal) {
          HStack {
            ForEach(Kind.allCases) { kind in
              NewCommandButtonView(content: {
                HStack {
                  Text("\(ModifierKey.command.keyValue)\(kind.rawKey)")
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                  Divider()
                    .frame(width: 1, height: 30)
                  NewCommandImageView(kind: kind)
                  Text(kind.rawValue)
                    .font(.system(.body, design: .rounded,weight: .semibold))
                }
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.vertical, 4)
                .background(Color(.windowBackgroundColor).opacity(0.75))
                .cornerRadius(8)
                .shadow(radius: 2)
              }, onKeyDown: { keyCode, _ in
                if keyCode == kVK_Return {
                  selection = kind
                  focused = nil
                }
              }) {
                selection = kind
                focused = nil
              }
              .keyboardShortcut(kind.key, modifiers: .command)
              .background(backgroundArrow(kind))
              .focusable()
              .focused($focused, equals: .application)
              .padding(.vertical)
              .padding(.leading, 16)
              .padding(.trailing, -8)
            }
          }
        }
        .padding(.bottom, -12)
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
          NewCommandOpenView($payload)
        }
      }
      .padding()
      .background(Color(nsColor: NSColor.textBackgroundColor))
      .cornerRadius(8)
      .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1),
              radius: 2,
              y: 2)
      .padding()

      Spacer()
      HStack {
        Spacer()
        Button(action: {}, label: { Text("Cancel") })
          .buttonStyle(.destructiveStyle)
        Button(action: { onSave(payload) }, label: { Text("Save") })
          .buttonStyle(.saveStyle)
      }
      .buttonStyle(.appStyle)
      .padding()
    }
    .enableInjection()
  }

  private func backgroundArrow(_ kind: Kind) -> some View {
    GeometryReader { proxy in
      Path { path in
        path.move(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
        path.addLine(to: CGPoint(x: proxy.size.width / 2 - 30, y: proxy.size.height))
        path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height + 12))
        path.addLine(to: CGPoint(x: proxy.size.width / 2 + 30, y: proxy.size.height))
      }
      .fill(Color(.windowBackgroundColor))
      .shadow(radius: 8, y: 6)
      .mask({
        GeometryReader { proxy in
          Rectangle()
            .fill(Color.red)
            .frame(height: 24)
            .offset(y: proxy.size.height)
        }
      })
      .opacity(selection == kind ? 1 : 0)
      .allowsHitTesting(false)
    }
  }
}

struct NewCommandImageView: View {
  @ObserveInjection var inject
  let kind: NewCommandView.Kind

  var body: some View {
    Group {
      switch kind {
      case .open:
        ZStack {
          Image(nsImage: NSWorkspace.shared.icon(forFile: "~/"))
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .rotationEffect(.degrees(5))
            .offset(.init(width: 4, height: -2))
          Image(nsImage: NSWorkspace.shared.icon(forFile: "~/".sanitizedPath))
            .resizable()
            .aspectRatio(1, contentMode: .fill)
        }
      case .url:
        Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"))
          .resizable()
          .aspectRatio(1, contentMode: .fit)
      case .application:
        Image(nsImage: NSWorkspace.shared.icon(forFile: "/Applications"))
          .resizable()
          .aspectRatio(1, contentMode: .fit)
      }
    }
    .frame(width: 30, height: 30)
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
      Label(title: { Text("Open URL:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())
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

      HStack(spacing: 32) {
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
      updatePayload()
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
  @EnvironmentObject var applicationStore: ApplicationStore
  @EnvironmentObject var openPanel: OpenPanelController
  @ObserveInjection var inject

  @Binding var payload: NewCommandPayload
  @State var application: Application?
  @State var path: String = "~/"

  init(_ payload: Binding<NewCommandPayload>) {
    _payload = payload
  }

  var body: some View {
    VStack {
      HStack {
        TextField("Path", text: $path)
          .textFieldStyle(LargeTextFieldStyle())
        Button("Browse", action: {
          openPanel.perform(.selectFile(type: nil, handler: { path in
            self.path = path
          }))
        })
        .buttonStyle(.gradientStyle(config: .init(nsColor: .systemBlue, grayscaleEffect: true)))
      }
      HStack(spacing: 32) {
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
    .onAppear { updatePayload() }
    .onChange(of: self.path, perform: { newValue in
      updatePayload()
    })
    .enableInjection()
  }

  private func updatePayload() {
    payload = .open(path: path, application: application)
  }
}

struct GradientButtonStyle: ButtonStyle {
  struct GradientConfiguration {
    let nsColor: NSColor
    let padding: Double
    let grayscaleEffect: Bool

    internal init(nsColor: NSColor, padding: Double = 4, grayscaleEffect: Bool = false) {
      self.nsColor = nsColor
      self.padding = padding
      self.grayscaleEffect = grayscaleEffect
    }
  }

  @ObserveInjection var inject
  @State private var isHovered = false
  @Environment(\.colorScheme) var colorScheme

  private let config: GradientConfiguration

  init(_ config: GradientConfiguration) {
    self.config = config
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(config.padding)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .fill(
              LinearGradient(stops: [
                .init(color: Color(config.nsColor), location: 0.0),
                .init(color: Color(config.nsColor.blended(withFraction: 0.5, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(config.nsColor))
            .opacity(isHovered ? 0.4 : 0.1)
        }
      )
      .grayscale(config.grayscaleEffect ? isHovered ? 0 : 1 : 0)
      .foregroundColor(
        Color(.labelColor)
      )
      .shadow(color: Color.black.opacity(isHovered ? 0.7 : 0.35),
              radius: configuration.isPressed ? 0 : isHovered ? 1 : 2,
              y: configuration.isPressed ? 0 : isHovered ? 1 : 2)
      .font(.system(.body, design: .rounded, weight: .semibold))
      .opacity(configuration.isPressed ? 0.6 : isHovered ? 1.0 : 0.8)
      .offset(y: configuration.isPressed ? 0.25 : 0.0)
      .onHover(perform: { value in
        self.isHovered = value
      })
      .enableInjection()
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
        .contentShape(RoundedRectangle(cornerRadius: 8))
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
