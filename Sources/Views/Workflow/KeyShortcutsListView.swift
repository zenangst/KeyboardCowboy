import SwiftUI

struct KeyShortcutsListView: View, Equatable {
  @ObserveInjection var inject
  enum Action {
    case add(KeyShortcut)
    case remove(KeyShortcut)
  }
  @Binding var keyboardShortcuts: [KeyShortcut]
  @Namespace var namespace
  @State var editing: KeyShortcut?
  let recorderStore: KeyShortcutRecorderStore
  var action: (Action) -> Void

  var body: some View {
    HStack(spacing: 0) {
      ScrollView(.horizontal, showsIndicators: true) {
        HStack {
          if keyboardShortcuts.isEmpty {
            RegularKeyIcon(letter: "Record keyboard shortcut")
              .fixedSize()
          } else {
            ForEach(keyboardShortcuts) { keyboardShortcut in
              responderView(keyboardShortcut)
            }
          }
        }.padding(4)
      }
      .onReceive(recorderStore.$recording) { recording in
        guard let editing = editing,
              let recording = recording,
              let index = keyboardShortcuts.firstIndex(where: {
                $0.id == editing.id
              }) else {
          return
        }

        switch recording {
        case .cancel:
          recorderStore.mode = .intercept
        case .delete:
          keyboardShortcuts.remove(at: index)
        case .valid(let recording):
          let newKeyshortcut = KeyShortcut(key: recording.key,
                                           modifiers: recording.modifiers)
          keyboardShortcuts[index] = newKeyshortcut
        default:
          break
        }
      }
      .frame(height: 36)

      Divider()
      Button(action: {
        let shortcut = KeyShortcut.empty()
        action(.add(shortcut))
        keyboardShortcuts.append(shortcut)
      },
             label: { Image(systemName: "plus") })
      .buttonStyle(KCButtonStyle())
      .font(.callout)
      .padding(.horizontal, 16)
    }
    .padding(4)
    .background(Color(.windowBackgroundColor))
    .cornerRadius(8)
    .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
    .enableInjection()
  }

  func responderView(_ keyboardShortcut: KeyShortcut) -> some View {
    ResponderView(keyboardShortcut, namespace: namespace, onClick: {
      editing = keyboardShortcut
      recorderStore.mode = .record
    }) { responder in
      key(keyboardShortcut, glow: Binding<Bool>(get: { editing == keyboardShortcut },
                                                set: { _ in }) )
      .background {
        RoundedRectangle(cornerRadius: 4)
          .stroke(
            responder.isFirstReponder ? .accentColor : Color(NSColor.systemGray.withSystemEffect(.disabled)),
            lineWidth: 1)
        ResponderBackgroundView(responder: responder, cornerRadius: 4)
      }
      .id(keyboardShortcut.id)
    }
    .fixedSize()
    .onDeleteCommand {
      keyboardShortcuts.removeAll(where: { $0.id == keyboardShortcut.id })
    }
  }

  func key(_ keyboardShortcut: KeyShortcut, glow: Binding<Bool>) -> some View {
    HStack(spacing: 4) {
      if let modifiers = keyboardShortcut.modifiers,
         !modifiers.isEmpty {
        ForEach(modifiers) { modifier in
          ModifierKeyIcon(key: modifier)
            .frame(minWidth: modifier == .shift || modifier == .command ? 48 : 32, maxWidth: 48)
        }
      }

      if keyboardShortcut.key.lowercased() == "space" {
        RegularKeyIcon(letter: "\(keyboardShortcut.key)",
                       glow: glow)
          .frame(width: 64)
          .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
      } else {
        RegularKeyIcon(letter: "\(keyboardShortcut.key)",
                       glow: glow)
          .frame(width: 32)
          .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
      }
    }
    .padding(2)
  }

  static func == (lhs: KeyShortcutsListView, rhs: KeyShortcutsListView) -> Bool {
    lhs.keyboardShortcuts == rhs.keyboardShortcuts
  }
}

struct KeyShortcutsListView_Previews: PreviewProvider {
    static var previews: some View {
      KeyShortcutsListView(
        keyboardShortcuts: .constant([
          .init(key: "↑"),
          .init(key: "↑"),

            .init(key: "↓"),
          .init(key: "↓"),

            .init(key: "←"),
          .init(key: "→"),

            .init(key: "←"),
          .init(key: "→"),

            .init(key: "B"),
          .init(key: "A"),
        ]),
        recorderStore: KeyShortcutRecorderStore(),
        action: { _ in })
    }
}
