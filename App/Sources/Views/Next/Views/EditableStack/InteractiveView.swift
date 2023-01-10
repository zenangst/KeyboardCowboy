import SwiftUI

enum InteractiveViewModifier {
  case command, shift, empty
}

struct InteractiveView<Content, Overlay>: View where Content : View, Overlay: View {
  @ObserveInjection var inject
  @Environment(\.controlActiveState) var controlActiveState
  @FocusState var isFocused: Bool
  @GestureState private var dragOffsetState: CGSize = .zero
  @State private var size: CGSize = .zero
  @State private var mouseDown: Bool = false
  @Binding var zIndex: Double
  private let animation: Animation
  private let id: CustomStringConvertible
  private let currentIndex: Int
  private let content: () -> Content
  private let overlay: () -> Overlay
  private let onDragChanged: (GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void
  private let onDragEnded: (GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void
  private let onClick: (InteractiveViewModifier) -> Void
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(animation: Animation,
       id: CustomStringConvertible,
       currentIndex: Int,
       zIndex: Binding<Double>,
       content: @autoclosure @escaping () -> Content,
       overlay: @escaping () -> Overlay,
       onClick: @escaping (InteractiveViewModifier) -> Void,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void,
       onDragChanged: @escaping (GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void,
       onDragEnded: @escaping (GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void) {
    self.animation = animation
    self.currentIndex = currentIndex
    self.id = id
    _zIndex = zIndex
    self.content = content
    self.overlay = overlay
    self.onClick = onClick
    self.onDragChanged = onDragChanged
    self.onDragEnded = onDragEnded
    self.onKeyDown = onKeyDown
  }

  var body: some View {
    content()
      .background(
        ZStack {
          FocusableProxy(id: id, onKeyDown: onKeyDown)
          GeometryReader { proxy in
            Color.clear
              .onAppear { size = proxy.size }
          }
        }
      )
      .overlay(content: overlay)
      .shadow(color: isFocused ? .accentColor.opacity(controlActiveState == .key ? 0.8 : 0.4) : Color(.sRGBLinear, white: 0, opacity: 0.33),
              radius: isFocused ? 1.0 : dragOffsetState != .zero ? 4.0 : 0.0)
      .zIndex(zIndex)
      .allowsHitTesting(dragOffsetState == .zero)
      .offset(dragOffsetState)
      .animation(Animation.linear(duration: 0.1), value: mouseDown)
      .highPriorityGesture(
        DragGesture()
          .updating($dragOffsetState) { (value, state, transaction) in
            state = value.translation
          }
          .onChanged({
            isFocused = false
            onDragChanged($0, size)
            mouseDown = true
          })
          .onEnded {
            onDragEnded($0, size)
            mouseDown = false
          }
      )
      .gesture(TapGesture().modifiers(.command)
        .onEnded({ _ in
          onClick(.command)
        })
      )
      .gesture(TapGesture().modifiers(.shift)
        .onEnded({ _ in
          onClick(.shift)
        })
      )
      .gesture(TapGesture()
        .onEnded({ _ in
          isFocused = true
          onClick(.empty)
        })
      )
      .focusable()
      .focused($isFocused)
      .enableInjection()
  }
}

