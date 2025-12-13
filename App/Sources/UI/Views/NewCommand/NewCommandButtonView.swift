import Bonzai
import HotSwiftUI
import SwiftUI

struct NewCommandButtonView<Content>: View where Content: View {
  @ObserveInjection var inject
  @FocusState private var isFocused: Bool

  private let content: () -> Content
  private let action: () -> Void
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(content: @escaping () -> Content, onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void, action: @escaping () -> Void) {
    self.content = content
    self.action = action
    self.onKeyDown = onKeyDown
  }

  var body: some View {
    Button(action: action) {
      content()
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .foregroundColor(isFocused ? Color(.controlAccentColor) : Color(.textColor))
    }
    .environment(\.buttonFocusEffect, false)
    .environment(\.buttonGrayscaleEffect, false)
    .environment(\.buttonHoverEffect, true)
    .environment(\.buttonBackgroundColor, .clear)
    .environment(\.buttonPadding, .small)
    .enableInjection()
  }
}
