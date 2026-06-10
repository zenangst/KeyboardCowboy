import HotSwiftUI
import SwiftUI

extension SidebarSplit {
  struct Label: View {
    @ObserveInjection private var inject
    private let text: String

    init(_ text: String) {
      self.text = text
    }

    var body: some View {
      SwiftUI.Label(title: { Text(text) }, icon: { EmptyView() })
        .font(.subheadline)
        .foregroundStyle(.tertiary)
        .enableInjection()
    }
  }
}
