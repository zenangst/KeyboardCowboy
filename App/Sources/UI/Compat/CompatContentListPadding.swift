import SwiftUI

struct CompatContentListPadding: ViewModifier {
  func body(content: Content) -> some View {
    if #available(macOS 15.0, *) {
      content
    } else {
      content
        .padding(5)
    }
  }
}

extension View {
  func compatContentListPadding() -> some View {
    modifier(CompatContentListPadding())
  }
}
