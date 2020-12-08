import SwiftUI
import ModelKit

public struct KeyboardShortcutList: View {
  public enum Action {
    case createKeyboardShortcut(ModelKit.KeyboardShortcut, index: Int, in: Workflow)
    case updateKeyboardShortcut(ModelKit.KeyboardShortcut, in: Workflow)
    case deleteKeyboardShortcut(ModelKit.KeyboardShortcut, in: Workflow)
    case moveCommand(ModelKit.KeyboardShortcut, to: Int, in: Workflow)
  }

  public enum UIAction {
    case create(ModelKit.KeyboardShortcut, Int)
    case update(ModelKit.KeyboardShortcut)
    case move(ModelKit.KeyboardShortcut, Int)
    case delete(ModelKit.KeyboardShortcut)
  }

  @Binding var workflow: Workflow

  let performAction: (UIAction) -> Void

  public var body: some View {
    VStack(spacing: 1) {
      ForEach(Array(workflow.keyboardShortcuts.enumerated()), id: \.element) { index, keyboardShortcut in
        MovableView(element: keyboardShortcut, dragHandler: { offset, _ in
          let indexOffset = Int(round(offset.height / 48))
          performAction(.move(keyboardShortcut, indexOffset))
        }, {
          HStack {
            Text("\(index + 1).").padding(.leading, 4)
            KeyboardRecorderView(keyboardShortcut: Binding<ModelKit.KeyboardShortcut?>(get: {
              keyboardShortcut
            }, set: { keyboardShortcut in
              if let keyboardShortcut = keyboardShortcut {
                performAction(.update(keyboardShortcut))
              }
            }))
            HStack(spacing: 4) {
              Button(action: {
                if let index = workflow.keyboardShortcuts.firstIndex(of: keyboardShortcut) {
                  performAction(.create(KeyboardShortcut.empty(), index + 1))
                }
              }, label: {
                Image(systemName: "plus.circle.fill")
                  .renderingMode(.template)
                  .foregroundColor(Color(.systemGreen))
              }).buttonStyle(PlainButtonStyle())
              Button(action: {
                performAction(.delete(keyboardShortcut))
              }, label: {
                Image(systemName: "minus.circle.fill")
                  .renderingMode(.template)
                  .foregroundColor(Color(.systemRed))
              }).buttonStyle(PlainButtonStyle())
              Text("≣")
                .font(.title)
                .padding(.leading, 8)
                .offset(x: 0, y: -2)
                .cursorOnHover(.closedHand)
            }
          }
          .frame(height: 48, alignment: .center)
          .padding(.horizontal)
          .background(Color(.windowBackgroundColor))
          .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
          .animation(.none)
        })
      }
    }
    .animation(.linear)
  }
}

// MARK: - Previews

struct KeyboardShortcutList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardShortcutList(workflow: .constant(ModelFactory().workflowDetail())) { _ in }
  }
}
