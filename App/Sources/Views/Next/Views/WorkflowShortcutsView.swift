import SwiftUI

struct WorkflowShortcutsView: View {
  @ObserveInjection var inject
  @State private var keyboardShortcuts: [DetailViewModel.KeyboardShortcut]

  init(_ keyboardShortcuts: [DetailViewModel.KeyboardShortcut]) {
    _keyboardShortcuts = .init(initialValue: keyboardShortcuts)
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 8) {
        ScrollView(.horizontal, showsIndicators: false) {
          EditableStack($keyboardShortcuts, axes: .horizontal, lazy: true, onMove: { _, _ in }) { keyboardShortcut in
            HStack(spacing: 6) {
              ForEach(keyboardShortcut.wrappedValue.modifiers) { modifier in
                  ModifierKeyIcon(key: modifier)
                  .frame(minWidth: modifier == .command || modifier == .shift ? 44 : 32, minHeight: 32)
              }
              RegularKeyIcon(letter: keyboardShortcut.wrappedValue.displayValue, width: 32, height: 32)
                .fixedSize(horizontal: true, vertical: true)
            }
            .padding(4)
            .background(
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(.disabledControlTextColor))
                .opacity(0.5)
            )
          }
        }
        Spacer()
        Divider()
        Button(action: {
          withAnimation {
            keyboardShortcuts.append(DetailViewModel.KeyboardShortcut.init(id: UUID().uuidString,
                                                                           displayValue: "H",
                                                                           modifiers: [.command]))
          }
        },
               label: { Image(systemName: "plus").frame(width: 10, height: 10) })
        .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
        .font(.callout)
        .padding(.leading, 8)
        .padding(.trailing, 16)
      }
      .padding(4)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(.windowBackgroundColor))
      )
      .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
    }
    .enableInjection()
  }
}
