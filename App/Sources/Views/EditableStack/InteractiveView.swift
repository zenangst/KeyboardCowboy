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
  @GestureState private var dragOffsetState: CGSize = .zero
  @Binding private var element: Element
  @Binding private var selectedColor: Color
  @State private var size: CGSize = .zero
  @State private var mouseDown: Bool = false
  @State private var zIndex: Double = 0
  private let animation: Animation
  private let index: Int
  @ViewBuilder
  private let content: (Binding<Element>, Int) -> Content
  private let overlay: (Element, Int) -> Overlay
  private let onDragChanged: (Element, Int, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void
  private let onDragEnded: (Element, Int, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void
  private let onClick: (Element, Int, InteractiveViewModifier) -> Void
  private let onKeyDown: (Element, Int, NSEvent.ModifierFlags) -> Void

  init(_ element: Binding<Element>,
       animation: Animation,
       index: Int,
       selectedColor: Binding<Color>,
       @ViewBuilder content: @escaping (Binding<Element>, Int) -> Content,
       overlay: @escaping (Element, Int) -> Overlay,
       onClick: @escaping (Element, Int, InteractiveViewModifier) -> Void,
       onKeyDown: @escaping (Element, Int, NSEvent.ModifierFlags) -> Void,
       onDragChanged: @escaping (Element, Int, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void,
       onDragEnded: @escaping (Element, Int, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void) {
    _element = element
    _selectedColor = selectedColor
    self.animation = animation
    self.index = index
    self.content = content
    self.overlay = overlay
    self.onClick = onClick
    self.onDragChanged = onDragChanged
    self.onDragEnded = onDragEnded
    self.onKeyDown = onKeyDown
  }

  var body: some View {
    content($element, index)
      .animation(nil, value: dragOffsetState)
      .background(
        ZStack {
          FocusableProxy(onKeyDown: {
            onKeyDown(element, $0, $1)
          })
          GeometryReader { proxy in
            Color.clear
              .onAppear { size = proxy.size }
          }
        }
      )
      .overlay(content: { overlay(element, index) })
      .shadow(color: isFocused ? selectedColor.opacity(controlActiveState == .key ? 0.8 : 0.4) : Color(.sRGBLinear, white: 0, opacity: 0.33),
              radius: isFocused ? 1.0 : dragOffsetState != .zero ? 4.0 : 0.0)
      .zIndex(zIndex)
      .allowsHitTesting(dragOffsetState == .zero)
      .offset(dragOffsetState)
      .animation(Animation.linear(duration: 0.1), value: mouseDown)
      .gesture(
        DragGesture()
          .updating($dragOffsetState) { (value, state, transaction) in
            state = value.translation
          }
          .onChanged({
            isFocused = false
            onDragChanged(element, index, $0, size)
            zIndex = 1
            mouseDown = true
          })
          .onEnded {
            zIndex = 0
            onDragEnded(element, index, $0, size)
            mouseDown = false
          }
      )
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

