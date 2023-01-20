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
  }

  @ObserveInjection var inject
  private let workflowId: Workflow.ID
  private let commandId: Command.ID?

  @Environment(\.controlActiveState) var controlActiveState
  @State private var payload: NewCommandPayload
  @State private var selection: Kind
  @State private var validation: NewCommandValidation = .needsValidation
  @State private var title: String
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
        NavigationSplitView(
          sidebar: sidebar,
          detail: { detail(title: $title) })
      } else {
        detail(title: $title)
          .toolbar(content: {
            ToolbarItem(id: UUID().uuidString) {
              Spacer()
            }
          })
          .padding(.top, 36)
      }
    }
    .frame(minWidth: 650, maxWidth: 850, minHeight: 400, maxHeight: 500)
    .enableInjection()
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
              Spacer()
              Text("\(ModifierKey.command.keyValue)\(kind.rawKey)")
                .font(.system(.caption, design: .monospaced))
                .multilineTextAlignment(.center)
                .tracking(2)
                .layoutPriority(1)
                .padding(2)
                .background(
                  RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.windowBackgroundColor))
                    .shadow(radius: 4)
                )
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(
              LinearGradient(stops: [
                .init(color: Color(.controlAccentColor.blended(withFraction: 0.25, of: .systemGreen)!), location: 0.0),
                .init(color: Color(.controlAccentColor.blended(withFraction: 0.25, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
                .opacity( kind == selection ? 0.5 : 0)
            )
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
          .focusable()
          .focused($focused, equals: .application)
          .padding(.horizontal, 8)
        }
      }
      .frame(minWidth: 210)
    }
    .background(Color(.windowBackgroundColor).opacity(0.6))
  }

  private func detail(title: Binding<String>) -> some View {
    VStack(spacing: 0) {
      TextField("", text: title)
        .font(.system(.body, design: .rounded,weight: .semibold))
        .allowsTightening(true)
        .opacity(controlActiveState == .key ? 1 : 0.6)
        .padding(.top, -28)
        .padding(.horizontal)
        .textFieldStyle(AppTextFieldStyle())
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: true, vertical: false)

      Group {
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
                            onSubmitAddress: { onSave(payload, title.wrappedValue) })
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
            let _ = Swift.print(payload)
            EmptyView()
          }
        case .type:
          NewCommandTypeView($payload, validation: $validation) {
            onSubmit()
          }
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(nsColor: NSColor.textBackgroundColor))
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
          .buttonStyle(.saveStyle)
          .keyboardShortcut(.defaultAction)
      }
      .buttonStyle(.appStyle)
      .padding()
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
