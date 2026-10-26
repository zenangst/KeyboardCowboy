import SwiftUI

extension SidebarSplit {
  @Injectable
  struct Label: View {
    private let text: String

    init(_ text: String) {
      self.text = text
    }

    var content: some View {
      SwiftUI.Label(title: { Text(text) }, icon: { EmptyView() })
        .font(.subheadline)
        .foregroundStyle(.tertiary)
    }
  }
}
