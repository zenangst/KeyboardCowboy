import Carbon
import SwiftUI

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
      case .keyboardShortcut:
        return "4"
      case .shortcut:
        return "5"
      case .script:
        return "6"
      case .type:
        return "7"
      case .system:
        return "8"
      }
    }
    var key: KeyEquivalent {
      return KeyEquivalent(rawKey.first!)
    }

    case application = "Application"
    case url = "URL"
    case open = "Open"
    case keyboardShortcut = "Keyboard Shortcut"
    case shortcut = "Shortcut"
    case script = "Script"
    case type = "Type"
    case system = "System Command"
  }

  private let workflowId: Workflow.ID
  private let commandId: Command.ID?

  @Environment(\.controlActiveState) var controlActiveState
  @State private var payload: NewCommandPayload
  @State private var selection: Kind
  @State private var validation: NewCommandValidation = .needsValidation
  @State private var title: String
  @State private var hasEdited: Bool = false
  private let onDismiss: () -> Void
  private let onSave: (NewCommandPayload, String) -> Void
  @FocusState var focused: Kind?

  init(workflowId: Workflow.ID,
       commandId: Command.ID?,
       title: String,
       selection: Kind,
       payload: NewCommandPayload,
       onDismiss: @escaping () -> Void,
       onSave: @escaping (NewCommandPayload, String) -> Void) {
    _selection = .init(initialValue: selection)
    _payload = .init(initialValue: payload)
    _title = .init(initialValue: title)
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
                Color(.windowBackgroundColor)
                Rectangle()
                  .fill(Color.white.opacity(0.2))
                  .frame(width: 1)
              })
            .frame(maxWidth: 200)
          detail(title: $title)
        }
      } else {
        detail(title: $title)
          .toolbar(content: {
            ToolbarItem(id: UUID().uuidString) {
              Spacer()
            }
          })
      }
    }
    .frame(minWidth: 710, minHeight: 400)
  }

  private func sidebar() -> some View {
    ScrollView(.vertical) {
      VStack {
        ForEach(Kind.allCases) { kind in
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
              Text("\(ModifierKey.command.keyValue)\(kind.rawKey)")
                .font(.system(.caption, design: .monospaced))
                .multilineTextAlignment(.center)
                .tracking(2)
                .layoutPriority(1)
                .padding(2)
                .background(
                  RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.textBackgroundColor))
                    .shadow(radius: 4)
                )
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
                  }, with: .color(Color.white.opacity(0.2)), lineWidth: 2)

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
          .focusable()
          .focused($focused, equals: .application)
          .padding(.horizontal, 4)
        }
      }
    }
  }

  private func sidebarBackgroundView() -> some View {
    Color(.textBackgroundColor)
  }

  private func detail(title: Binding<String>) -> some View {
    VStack(spacing: 0) {
      TextField("", text: title, onEditingChanged: { value in
        hasEdited = true
      })
      .frame(maxWidth: 420)
      .font(.system(.body, design: .rounded,weight: .semibold))
      .allowsTightening(true)
      .opacity(controlActiveState == .key ? 1 : 0.6)
      .padding(.top, -28)
      .padding(.horizontal)
      .textFieldStyle(AppTextFieldStyle())
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: true, vertical: false)
      .onChange(of: payload, perform: { newValue in
        guard !hasEdited else { return }
        title.wrappedValue = newValue.title
      })

      selectedView(selection)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(.windowBackgroundColor))
        )
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1),
                radius: 2,
                y: 2)
        .padding(.horizontal)

      Spacer()

      HStack {
        Spacer()
        Button(action: onDismiss, label: { Text("Cancel") })
          .buttonStyle(.gradientStyle(config: .init(nsColor: .red, grayscaleEffect: true)))
        Button(action: onSubmit, label: { Text("Save") })
          .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, hoverEffect: false)))
          .keyboardShortcut(.defaultAction)
      }
      .buttonStyle(.appStyle)
      .padding()
    }
    .padding(.top, 36)
    .background(Color(.textBackgroundColor))
  }

  @ViewBuilder
  private func selectedView(_ selection: Kind) -> some View {
    switch selection {
    case .application:
      if case .application(let application, let action, let inBackground, let hideWhenRunning, let ifNotRunning) = payload {
        NewCommandApplicationView($payload, application: application, action: action,
                                  inBackground: inBackground, hideWhenRunning: hideWhenRunning,
                                  ifNotRunning: ifNotRunning, validation: $validation)
      } else {
        NewCommandApplicationView($payload, application: nil, action: .open,
                                  inBackground: false, hideWhenRunning: false,
                                  ifNotRunning: false, validation: $validation)
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
      if case .script(let value, let kind, let scriptExtension) = payload {
        NewCommandScriptView($payload,
                             kind: kind,
                             value: value,
                             scriptExtension: scriptExtension,
                             validation: $validation)
      } else {
        NewCommandScriptView($payload, kind: .file, value: "",
                             scriptExtension: .shellScript,
                             validation: $validation)
      }
    case .type:
      NewCommandTypeView($payload, validation: $validation) {
        onSubmit()
      }
    case .system:
      NewCommandSystemCommandView($payload, validation: $validation)
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
      selection: .system,
      payload: .application(application: nil, action: .open, inBackground: false, hideWhenRunning: false, ifNotRunning: false),
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
