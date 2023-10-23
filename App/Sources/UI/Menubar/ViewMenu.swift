import SwiftUI

struct ViewMenu: View {
  var onFilter: () -> Void

  var body: some View {
    Button("Filter Workflows", action: onFilter)
      .keyboardShortcut("f", modifiers: [.option, .command])
  }
}
