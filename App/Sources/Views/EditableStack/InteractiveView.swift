import SwiftUI

enum InteractiveViewModifier {
  case command, shift, empty
}

struct InteractiveView<Element, Content>: View where Content : View,
                                                     Element: Hashable,
                                                     Element: Identifiable,
                                                     Element.ID: Hashable,
                                                     Element.ID: CustomStringConvertible {
  private let index: Int
  @ViewBuilder
  private let content: () -> Content
  private let element: Element
  private let onClick: (Element, Int, InteractiveViewModifier) -> Void
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(_ element: Element, index: Int,
       @ViewBuilder content: @escaping () -> Content,
       onClick: @escaping (Element, Int, InteractiveViewModifier) -> Void,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.element = element
    self.index = index
    self.content = content
    self.onClick = onClick
    self.onKeyDown = onKeyDown
  }

  var body: some View {
    content()
      .background(FocusableProxy(onKeyDown: { onKeyDown($0, $1) }))
      .gesture(TapGesture().modifiers(.command)
        .onEnded({ _ in
          onClick(element, index, .command)
        })
      )
      .gesture(TapGesture().modifiers(.shift)
        .onEnded({ _ in
          onClick(element, index, .shift)
        })
      )
      .gesture(TapGesture()
        .onEnded({ _ in
          onClick(element, index, .empty)
        })
      )
    }
}
