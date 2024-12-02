import Carbon
import SwiftUI
import Bonzai

@MainActor
struct NewCommandView: View {
  enum Kind: String, CaseIterable, Hashable, Identifiable {
    var id: String { self.rawValue }
    var rawKey: String {
      let value = Self.allCases.firstIndex(of: self)! + 1

      if value == 10 {
        return "0"
      }

      return String(value)
    }
    var key: KeyEquivalent {
      return KeyEquivalent(rawKey.first!)
    }

    case application = "Application"
    case menuBar = "Menu Bar"
    case uiElement = "UI Element"
    case url = "URL"
    case open = "Open"
    case keyboardShortcut = "Keyboard Shortcut"
    case shortcut = "Shortcut"
    case script = "Script"
    case text = "Text"
    case system = "System"
    case bundled = "Prebuilt"
    case windowManagement = "Window Management"
    case mouse = "Mouse Command"
    case builtIn = "Built-In"
  }

  private let workflowId: Workflow.ID
  private let commandId: Command.ID?

  @Environment(\.controlActiveState) var controlActiveState
  @State private var payload: NewCommandPayload
  @State private var selection: Kind
  @State private var validation: NewCommandValidation
  @State private var title: String
  @State private var saveButtonColor: ZenColor = .systemGreen
  @StateObject private var edited = Edited()
  private let onDismiss: () -> Void
  private let onSave: (NewCommandPayload, String) -> Void
  @FocusState var focused: Kind?

  init(workflowId: Workflow.ID,
       commandId: Command.ID?,
       title: String,
       selection: Kind,
       payload: NewCommandPayload,
       validation: NewCommandValidation = .needsValidation,
       onDismiss: @escaping () -> Void,
       onSave: @escaping (NewCommandPayload, String) -> Void) {
    _selection = .init(initialValue: selection)
    _payload = .init(initialValue: payload)
    _title = .init(initialValue: title)
    _validation = .init(initialValue: validation)
    self.workflowId = workflowId
    self.commandId = commandId
    self.onSave = onSave
    self.onDismiss = onDismiss
  }

  var body: some View {
    Group {
      if commandId == nil {
        HStack(spacing: 0) {
          sidebar()
            .padding(.top, 36)
            .background(
              HStack(spacing: 0) {
                ZStack {
                  ZenVisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow, state: .active)
                  LinearGradient(stops: [
                    .init(color: Color(nsColor: .textBackgroundColor).opacity(0.4), location: 0),
                    .init(color: Color(nsColor: .textBackgroundColor).opacity(0.8), location: 1)
                  ], startPoint: .top, endPoint: .bottom)
                }
                .ignoresSafeArea()
                Rectangle()
                  .fill(Color.white.opacity(0.1))
                  .frame(width: 1)
              })
            .frame(maxWidth: 235)
          detailView
        }
      } else {
        detailView
          .toolbar(content: {
            ToolbarItem(id: UUID().uuidString) {
              Spacer()
            }
          })
      }
    }
    .frame(minWidth: 710, minHeight: 560)
  }

  private func sidebar() -> some View {
    ScrollView(.vertical) {
      VStack {
        ForEach(Array(zip(Kind.allCases.indices, Kind.allCases)), id: \.1) { offset, kind in
          NewCommandButtonView(content: {
            HStack {
              NewCommandImageView(kind: kind)
              Text(kind.rawValue)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.body)
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)
              Spacer()
              if offset < 10 {
                KeyboardIconView("\(ModifierKey.leftCommand.keyValue)\(kind.rawKey)", size: 24)
              }
            }
            .padding(.leading, 4)
            .padding(.trailing, 18)
            .padding(.vertical, 4)
            .background(
              Canvas(rendersAsynchronously: true) { context, size in
                if kind == selection {
                  context.stroke(Path { path in
                    path.move(to: .init(x: size.width, y: 2))
                    path.addLine(to: .init(x: size.width - 12, y: size.height / 2))
                    path.addLine(to: .init(x: size.width, y: size.height - 2))
                  }, with: .color(Color.white.opacity(0.1)), lineWidth: 2)

                  context.fill(Path { path in
                    path.move(to: .init(x: size.width, y: 2))
                    path.addLine(to: .init(x: size.width - 12, y: size.height / 2))
                    path.addLine(to: .init(x: size.width, y: size.height - 2))
                  }, with: .color(Color(.textBackgroundColor)))
                }
              }
            )
            .offset(x: 4)
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
          .focused($focused, equals: .application)
          .padding(.horizontal, 4)
        }
      }
      .padding(.bottom)
    }
  }

  private var detailView: some View {
    VStack(spacing: 0) {
      TextField("", text: $title)
      .onReceive(LocalEventMonitor.shared.$event
        .compactMap { $0 }
        .filter({ $0.type == .keyUp }), perform: { event in
        // Mark the content as edited if any of these key codes match.
        // When it is marked as edited by the user, then we shouldn't change it
        // when the user picks another application.
        let validKeyCodes: Set<Int> = [
          kVK_Delete, kVK_Space, kVK_ForwardDelete
        ]
        if validKeyCodes.contains(Int(event.keyCode)) {
          edited.state = true
        }
      })
      .overlay {
        // This invisible button captures the return key with the command modifier attached. If the validation passes, the user will create a new command.
        Button("", action: {
          onSubmit()
        })
          .opacity(0.0)
          .keyboardShortcut(.return, modifiers: [.command])
      }
      .frame(maxWidth: 420)
      .font(.system(.body, design: .rounded,weight: .semibold))
      .allowsTightening(true)
      .opacity(controlActiveState == .key ? 1 : 0.6)
      .padding(.top, -28)
      .padding(.horizontal)
      .textFieldStyle(.regular(Color(.windowBackgroundColor)))
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: true, vertical: false)
      .onChange(of: payload, perform: { newValue in
        guard !edited.state else { return }
        $title.wrappedValue = newValue.title
      })
      .onChange(of: validation) { newValue in
        switch newValue {
        case .invalid:
          saveButtonColor = .systemRed
        case .unknown, .needsValidation, .valid:
          saveButtonColor = .systemGreen
        }
      }

      selectedView(selection)
        .roundedContainer()

      Spacer()

      HStack {
        Spacer()
        Button(action: onDismiss, label: { Text("Cancel") })
          .buttonStyle(.zen(.init(color: .systemRed, grayscaleEffect: .constant(true))))
        Button(action: { onSubmit() }, label: { Text("Save") })
          .buttonStyle(.zen(.init(color: saveButtonColor, hoverEffect: .constant(false))))
          .keyboardShortcut(.defaultAction)
      }
      .padding()
    }
    .padding(.top, 36)
    .background(Color(.textBackgroundColor))
  }

  @ViewBuilder @MainActor
  private func selectedView(_ selection: Kind) -> some View {
    VStack(alignment: .leading) {
      switch selection {
      case .application:
        if case .application(let application, let action, let inBackground,
                             let hideWhenRunning, let ifNotRunning, let waitForAppToLaunch) = payload {
          NewCommandApplicationView($payload, application: application, action: action,
                                    inBackground: inBackground, hideWhenRunning: hideWhenRunning,
                                    ifNotRunning: ifNotRunning, waitForAppToLaunch: waitForAppToLaunch, validation: $validation)
        } else {
          NewCommandApplicationView($payload, application: nil, action: .open,
                                    inBackground: false, hideWhenRunning: false,
                                    ifNotRunning: false, waitForAppToLaunch: false,
                                    validation: $validation)
        }
      case .url:
        NewCommandURLView($payload, validation: $validation,
                          onSubmitAddress: { onSave(payload, $title.wrappedValue) })
      case .open:
        NewCommandOpenView($payload, validation: $validation)
      case .keyboardShortcut:
        NewCommandKeyboardShortcutView($payload, validation: $validation)
      case .shortcut:
        NewCommandShortcutView($payload, validation: $validation)
      case .script:
        NewCommandScriptView($payload, kind: .source, value: "",
                             scriptExtension: .shellScript,
                             validation: $validation) { onSave($0, $title.wrappedValue) }
      case .text:             NewCommandTextView(payload: $payload, validation: $validation, onSubmit: onSubmit)
      case .system:           NewCommandSystemCommandView($payload, validation: $validation)
      case .menuBar:          NewCommandMenuBarView($payload, validation: $validation)
      case .mouse:            NewCommandMouseView(payload: $payload, validation: $validation)
      case .windowManagement: NewCommandWindowManagementView($payload, validation: $validation)
      case .builtIn:          NewCommandBuiltInView($payload, validation: $validation)
      case .uiElement:        NewCommandUIElementView($payload, validation: $validation)
      case .bundled:          NewCommandBundledView($payload, validation: $validation)
      }
    }
  }

  private func onSubmit() {
    guard validation == .valid else {
      withAnimation {
        validation = .needsValidation
      }
      return
    }
    onSave(payload, title)
  }
}

struct NewCommandView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .bundled,
      payload: .text(.init(.insertText(.init("Hello, world!", mode: .instant)))),
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
    .frame(height: 560)
  }
}

fileprivate final class Edited: ObservableObject {
  @Published var state = false
}
