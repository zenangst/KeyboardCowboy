import SwiftUI

struct WorkflowShortcutsView: View {
  @ObserveInjection var inject
  @State private var keyboardShortcuts: [DetailViewModel.KeyboardShortcut]

  init(_ keyboardShortcuts: [DetailViewModel.KeyboardShortcut]) {
    _keyboardShortcuts = .init(initialValue: keyboardShortcuts)
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ScrollView(.horizontal, showsIndicators: false) {
          EditableStack($keyboardShortcuts, axes: .horizontal, lazy: true, onMove: { _, _ in }) { keyboardShortcut in
            HStack(spacing: 2) {
              ModifierKeyIcon(key: .function)
                .frame(width: 32)
              RegularKeyIcon(letter: keyboardShortcut.displayValue.wrappedValue)
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
        Button(action: {},
               label: { Image(systemName: "plus") })
        .buttonStyle(KCButtonStyle())
        .font(.callout)
        .padding(.horizontal, 16)
      }
      .padding(4)
      .background(Color(.windowBackgroundColor))
      .cornerRadius(8)
      .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
    }
    .enableInjection()
  }
}
