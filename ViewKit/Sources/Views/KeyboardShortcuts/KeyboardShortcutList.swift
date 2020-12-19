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
      if !workflow.keyboardShortcuts.isEmpty {
        list
      } else {
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
  var list: some View {
    HStack {
      ScrollView(.horizontal) {
        HStack(spacing: 4) {
          ForEach(workflow.keyboardShortcuts) { keyboardShortcut in
            MovableStack(axis: .horizontal, element: keyboardShortcut, dragHandler: { offset, _ in
              let indexOffset = Int(round(offset.width / 48))
              performAction(.move(keyboardShortcut, offset: indexOffset, in: workflow))
              selection = nil
            }, content: { item(keyboardShortcut) })
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

  func item(_ keyboardShortcut: ModelKit.KeyboardShortcut) -> some View {
    KeyboardSequenceItem(
      title: keyboardShortcut.modifersDisplayValue,
      subtitle: keyboardShortcut.key
    )
      .frame(minWidth: 32)
    .padding(2)
    .foregroundColor(
      Color(selection == keyboardShortcut
              ? NSColor.controlAccentColor.withSystemEffect(.pressed)
              : NSColor.textColor
      )
    )
    .background(
      Color(selection == keyboardShortcut
              ? NSColor.controlAccentColor.withAlphaComponent(0.33)
              : NSColor.textBackgroundColor
      )
    )
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .stroke(
          selection == keyboardShortcut
          ? Color(.controlAccentColor)
            : Color(NSColor.systemGray.withSystemEffect(.disabled)),
          lineWidth: 1)
    )
    .cornerRadius(4)
    .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
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
