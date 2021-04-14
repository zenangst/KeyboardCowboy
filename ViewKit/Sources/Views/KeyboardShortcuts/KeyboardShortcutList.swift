import Combine
import SwiftUI
import BridgeKit
import ModelKit

class TransportDelegate: ObservableObject, TransportControllerReceiver {
  @Published var state: KeyboardShortcutUpdateContext?

  func receive(_ context: KeyboardShortcutUpdateContext) {
    state = context
  }
}

public struct KeyboardShortcutList: View {
  // swiftlint:disable weak_delegate
  @StateObject var transportDelegate = TransportDelegate()

  public enum UIAction {
    case create(ModelKit.KeyboardShortcut, offset: Int, in: Workflow)
    case update(ModelKit.KeyboardShortcut, in: Workflow)
    case move(ModelKit.KeyboardShortcut, offset: Int, in: Workflow)
    case delete(ModelKit.KeyboardShortcut, in: Workflow)
  }

  @State var isShowingError: Bool = false
  @State var validationError: String?
  @Binding var workflow: Workflow
  @State var selection: ModelKit.KeyboardShortcut?
  let performAction: (UIAction) -> Void

  public var body: some View {
    VStack(spacing: 1) {
      switch workflow.trigger {
      case .keyboardShortcuts(let shortcuts):
        list(shortcuts)
      case .none:
        addButton
      }
    }.onReceive(transportDelegate.$state, perform: { context in
      guard let selection = selection,
            let context = context else {
        return
      }

      switch context {
      case .delete:
        performAction(.delete(selection, in: workflow))
      case .cancel:
        self.selection = nil
      case .systemShortcut:
        validationError = "This keyboard shortcut is taken by the system."
        isShowingError = true
      case .valid(let keyboardShortcut):
        let updatedKeyboardShortcut = ModelKit.KeyboardShortcut(
          id: selection.id,
          key: keyboardShortcut.key,
          modifiers: keyboardShortcut.modifiers)
        performAction(.update(updatedKeyboardShortcut, in: workflow))
      }
    })
  }
}

// MARK: Extensions

extension KeyboardShortcutList {
  func list(_ keyboardShortcuts: [ModelKit.KeyboardShortcut]) -> some View {
    HStack {
      ScrollView(.horizontal) {
        HStack(spacing: 20) {
          ForEach(keyboardShortcuts) { keyboardShortcut in
            MovableStack(axis: .horizontal, element: keyboardShortcut, dragHandler: { offset, _ in
              let indexOffset = Int(round(offset.width / 48))
              performAction(.move(keyboardShortcut, offset: indexOffset, in: workflow))
              selection = nil
            }, content: {
              key(keyboardShortcut)
                .frame(height: 32)
            })
            .onTapGesture {
              onTap()
              selection = keyboardShortcut
            }
          }
        }
        .padding([.vertical], 4)
      }.onTapGesture {
        addKeyboardShortcut()
      }
      Button(action: addKeyboardShortcut,
             label: { Image(systemName: "plus.square.fill") })
        .buttonStyle(PlainButtonStyle())
        .padding(.trailing, 4)
    }
    .padding([.leading, .trailing], 4)
    .background(Color(.windowBackgroundColor))
    .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
    .popover(isPresented: $isShowingError,
             attachmentAnchor: .point(UnitPoint.bottom),
             arrowEdge: .bottom,
             content: {
              Text("\(validationError ?? "")")
                .padding([.leading, .trailing, .bottom], 10)
                .padding(.top, 10)

    })
  }

  func key(_ keyboardShortcut: ModelKit.KeyboardShortcut) -> some View {
    HStack(spacing: 4) {
      if let modifiers = keyboardShortcut.modifiers,
         !modifiers.isEmpty {
        ForEach(modifiers) { modifier in
          ModifierKeyIcon(key: modifier)
            .frame(minWidth: modifier == .shift || modifier == .command ? 48 : 32, maxWidth: 48)
        }
      }

      RegularKeyIcon(letter: "\(keyboardShortcut.key)",
                     glow: false)
        .aspectRatio(contentMode: .fit)
        .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
    }
    .padding(2)
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .stroke(
          selection == keyboardShortcut
          ? Color(.controlAccentColor)
            : Color(NSColor.systemGray.withSystemEffect(.disabled)),
          lineWidth: 1)
    )
  }

  var addButton: some View {
    AddButton(text: "Add Keyboard Shortcut",
              alignment: .center,
              action: addKeyboardShortcut)
      .padding(.vertical, 8)
  }

  func onTap() {
    TransportController.shared.receiver = transportDelegate
    NotificationCenter.default.post(.enableRecordingHotKeys)
  }

  func addKeyboardShortcut() {
    let newShortcut = ModelKit.KeyboardShortcut.empty()
    performAction(.create(newShortcut,
                          offset: 9999,
                          in: workflow))
    selection = newShortcut
    onTap()
  }
}

// MARK: Previews

struct KeyboardShortcutList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardShortcutList(workflow: .constant(ModelFactory().workflowDetail()),
                         performAction: { _ in })
  }
}
