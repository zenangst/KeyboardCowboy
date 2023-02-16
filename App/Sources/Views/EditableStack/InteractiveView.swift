import SwiftUI

enum InteractiveViewModifier {
  case command, shift, empty
}

struct InteractiveView<Element, Content, Overlay>: View where Content : View,
                                                              Overlay: View,
                                                              Element: Hashable,
                                                              Element: Identifiable {
  @Environment(\.controlActiveState) var controlActiveState
  @FocusState var isFocused: Bool
  @Binding private var element: Element
  @Binding private var selectedColor: Color
  private let index: Int
  @ViewBuilder
  private let content: (Binding<Element>, Int) -> Content
  private let overlay: (Element, Int) -> Overlay
  private let onClick: (Element, Int, InteractiveViewModifier) -> Void
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(_ element: Binding<Element>, index: Int,
       selectedColor: Binding<Color>,
       @ViewBuilder content: @escaping (Binding<Element>, Int) -> Content,
       @ViewBuilder overlay: @escaping (Element, Int) -> Overlay,
       onClick: @escaping (Element, Int, InteractiveViewModifier) -> Void,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    _element = element
    _selectedColor = selectedColor
    self.index = index
    self.content = content
    self.overlay = overlay
    self.onClick = onClick
    self.onKeyDown = onKeyDown
  }

  var body: some View {
    content($element, index)
      .background(FocusableProxy(onKeyDown: { onKeyDown($0, $1) }))
      .shadow(color: isFocused ? selectedColor.opacity(controlActiveState == .key ? 0.8 : 0.4) : Color(.sRGBLinear, white: 0, opacity: 0.33),
              radius: isFocused ? 1.0 : 0.0)
      .overlay(content: { overlay(element, index) })
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
          isFocused = true
          onClick(element, index, .empty)
        })
      )
      .focusable()
      .focused($isFocused)
    }
}
