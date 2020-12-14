import SwiftUI
import ModelKit

public struct KeyboardShortcutList: View {
  public enum UIAction {
    case create(ModelKit.KeyboardShortcut, offset: Int, in: Workflow)
    case update(ModelKit.KeyboardShortcut, in: Workflow)
    case move(ModelKit.KeyboardShortcut, offset: Int, in: Workflow)
    case delete(ModelKit.KeyboardShortcut, in: Workflow)
  }

  @Binding var workflow: Workflow
  let performAction: (UIAction) -> Void

  public var body: some View {
    VStack(spacing: 1) {
      if !workflow.keyboardShortcuts.isEmpty {
        list
      } else {
        addButton
      }
    }
  }
}

// MARK: Extensions

extension KeyboardShortcutList {
  var list: some View {
    ForEach(Array(workflow.keyboardShortcuts.enumerated()), id: \.element) { index, keyboardShortcut in
      MovableView(element: keyboardShortcut, dragHandler: { offset, _ in
        let indexOffset = Int(round(offset.height / 48))
        performAction(.move(keyboardShortcut, offset: indexOffset, in: workflow))
      }, {
        HStack {
          Text("\(index + 1).").padding(.leading, 4)
          KeyboardRecorderView(keyboardShortcut: Binding<ModelKit.KeyboardShortcut?>(get: {
            keyboardShortcut
          }, set: { keyboardShortcut in
            if let keyboardShortcut = keyboardShortcut {
              performAction(.update(keyboardShortcut, in: workflow))
            }
          }))
          HStack(spacing: 4) {
            Button(action: {
              if let index = workflow.keyboardShortcuts.firstIndex(of: keyboardShortcut) {
                performAction(.create(KeyboardShortcut.empty(), offset: index + 1, in: workflow))
              }
            }, label: {
              Image(systemName: "plus.circle.fill")
                .renderingMode(.template)
                .foregroundColor(Color(.systemGreen))
            }).buttonStyle(PlainButtonStyle())
            Button(action: {
              performAction(.delete(keyboardShortcut, in: workflow))
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
      })
    }
  }

  var addButton: some View {
    AddButton(text: "Add Keyboard Shortcut",
              alignment: .center,
              action: { performAction(.create(ModelKit.KeyboardShortcut.empty(),
                                              offset: 9999,
                                              in: workflow)) })
      .padding(.vertical, 8)
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
