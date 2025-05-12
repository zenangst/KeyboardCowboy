import SwiftUI

struct LegacyOnTapFix: ViewModifier {
  let onTap: () -> Void

  func body(content: Content) -> some View {
    if #available(macOS 14.0, *) {
      content
    } else {
      content
        .onTapGesture(perform: onTap)
    }
  }
}
