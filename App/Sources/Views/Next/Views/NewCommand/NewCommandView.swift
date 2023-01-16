import Carbon
import SwiftUI

struct NewCommandView: View {
  enum Validation: Identifiable, Equatable {
    var id: String { rawValue }
    case unknown
    case needsValidation
    case invalid(reason: String?)
    case valid

    var rawValue: String {
      switch self {
      case .valid:
        return "valid"
      case .needsValidation:
        return "needsValidation"
      case .unknown:
        return "unknown"
      case .invalid:
        return "invalid"
      }
    }

    var isInvalid: Bool {
      if case .invalid = self {
        return true
      } else {
        return false
      }
    }

    var isValid: Bool {
      if case .valid = self {
        return true
      } else {
        return false
      }
    }
  }
  
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
      case .type:
        return "6"
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
    case type = "Type"
  }

  @ObserveInjection var inject
  let workflowId: Workflow.ID

  @Environment(\.controlActiveState) var controlActiveState
  @State private var payload: NewCommandPayload = .placeholder
  @State private var selection: Kind = .type
  @State private var validation: Validation = .needsValidation
  private let onDismiss: () -> Void
  private let onSave: (NewCommandPayload) -> Void
  @FocusState var focused: Kind?

  init(workflowId: Workflow.ID,
       onDismiss: @escaping () -> Void,
       onSave: @escaping (NewCommandPayload) -> Void) {
    self.workflowId = workflowId
    self.onSave = onSave
    self.onDismiss = onDismiss
  }

  var body: some View {
    NavigationSplitView(sidebar: sidebar, detail: detail)
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

  private func detail() -> some View {
    VStack(spacing: 0) {
      Text("New command")
        .font(.system(.body, design: .rounded,weight: .semibold))
        .allowsTightening(true)
        .opacity(controlActiveState == .key ? 1 : 0.6)
        .padding(.top, -28)

      Group {
        switch selection {
        case .application:
          NewCommandApplicationView($payload, validation: $validation)
        case .url:
          NewCommandURLView($payload, validation: $validation,
                            onSubmitAddress: { onSave(payload) })
        case .open:
          NewCommandOpenView($payload, validation: $validation)
        case .keyboardShortcut:
          NewCommandKeyboardShortcutView($payload, validation: $validation)
        case .shortcut:
          NewCommandShortcutView($payload, validation: $validation)
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
          .keyboardShortcut(.cancelAction)
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
    onSave(payload)
  }
}
