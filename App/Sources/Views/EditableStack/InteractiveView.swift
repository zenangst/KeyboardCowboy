import SwiftUI

enum InteractiveViewModifier {
  case command, shift, empty
}

struct InteractiveView<ElementID, Content, Overlay>: View where Content : View,
                                                                Overlay: View,
                                                                ElementID: Hashable {
  @Environment(\.controlActiveState) var controlActiveState
  @FocusState var isFocused: Bool
  @GestureState private var dragOffsetState: CGSize = .zero
  @Binding var selectedColor: Color
  @State private var size: CGSize = .zero
  @State private var mouseDown: Bool = false
  @State var zIndex: Double = 0
  private let animation: Animation
  private let id: ElementID
  private let index: Int
  @ViewBuilder
  private let content: () -> Content
  private let overlay: () -> Overlay
  private let onDragChanged: (ElementID, Int, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void
  private let onDragEnded: (ElementID, Int, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void
  private let onClick: (ElementID, Int, InteractiveViewModifier) -> Void
  private let onKeyDown: (ElementID, Int, NSEvent.ModifierFlags) -> Void

  init(animation: Animation,
       id: ElementID,
       index: Int,
       selectedColor: Binding<Color>,
       @ViewBuilder content: @escaping () -> Content,
       overlay: @escaping () -> Overlay,
       onClick: @escaping (ElementID, Int, InteractiveViewModifier) -> Void,
       onKeyDown: @escaping (ElementID, Int, NSEvent.ModifierFlags) -> Void,
       onDragChanged: @escaping (ElementID, Int, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void,
       onDragEnded: @escaping (ElementID, Int, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void) {
    _selectedColor = selectedColor
    self.animation = animation
    self.id = id
    self.index = index
    self.content = content
    self.overlay = overlay
    self.onClick = onClick
    self.onDragChanged = onDragChanged
    self.onDragEnded = onDragEnded
    self.onKeyDown = onKeyDown
  }

  var body: some View {
    content()
      .animation(nil, value: dragOffsetState)
      .background(
        ZStack {
          FocusableProxy(onKeyDown: {
            onKeyDown(id, $0, $1)
          })
          GeometryReader { proxy in
            Color.clear
              .onAppear { size = proxy.size }
          }
        }
      )
      .overlay(content: overlay)
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
            onDragChanged(id, index, $0, size)
            zIndex = 1
            mouseDown = true
          })
          .onEnded {
            zIndex = 0
            onDragEnded(id, index, $0, size)
            mouseDown = false
          }
      )
      .gesture(TapGesture().modifiers(.command)
        .onEnded({ _ in
          onClick(id, index, .command)
        })
      )
      .gesture(TapGesture().modifiers(.shift)
        .onEnded({ _ in
          onClick(id, index, .shift)
        })
      )
      .gesture(TapGesture()
        .onEnded({ _ in
          isFocused = true
          onClick(id, index, .empty)
        })
      )
      .focusable()
      .focused($isFocused)
    }
}

