import Carbon
import SwiftUI

struct NewCommandView: View {
  enum Validation {
    case unknown
    case needsValidation
    case invalid
    case valid
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
  @State private var payload: NewCommandPayload = .placeholder
  @State private var selection: Kind = .application
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
              NewCommandImageView(kind: kind)
              Text(kind.rawValue)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.body)
                .layoutPriority(1)
              Spacer()
            }
            .padding(.leading, 4)
            .padding(.trailing, 16)
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
    }
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
          NewCommandOpenView($payload)
        }
      }
      .padding()
      .background(Color(nsColor: NSColor.textBackgroundColor))
      .cornerRadius(8)
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
        Button(action: {
          guard validation == .valid else {
            validation = .needsValidation
            return
          }
          onSave(payload)
        }, label: { Text("Save") })
          .buttonStyle(.saveStyle)
          .keyboardShortcut(.defaultAction)
      }
      .buttonStyle(.appStyle)
      .padding()
    }
  }
}
