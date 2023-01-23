import SwiftUI

enum InteractiveViewModifier {
  case command, shift, empty
}

struct InteractiveView<ElementID, Content, Overlay>: View where Content : View, Overlay: View {
  @ObserveInjection var inject
  @Environment(\.controlActiveState) var controlActiveState
  @FocusState var isFocused: Bool
  @GestureState private var dragOffsetState: CGSize = .zero
  @State private var size: CGSize = .zero
  @State private var mouseDown: Bool = false
  @State var zIndex: Double = 0
  private let animation: Animation
  private let id: ElementID
  @ViewBuilder
  private let content: () -> Content
  private let overlay: () -> Overlay
  private let onDragChanged: (ElementID, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void
  private let onDragEnded: (ElementID, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void
  private let onClick: (ElementID, InteractiveViewModifier) -> Void
  private let onKeyDown: (ElementID, Int, NSEvent.ModifierFlags) -> Void

  init(animation: Animation,
       id: ElementID,
//       zIndex: Binding<Double>,
       @ViewBuilder content: @escaping () -> Content,
       overlay: @escaping () -> Overlay,
       onClick: @escaping (ElementID, InteractiveViewModifier) -> Void,
       onKeyDown: @escaping (ElementID, Int, NSEvent.ModifierFlags) -> Void,
       onDragChanged: @escaping (ElementID, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void,
       onDragEnded: @escaping (ElementID, GestureStateGesture<DragGesture, CGSize>.Value, CGSize) -> Void) {
    self.animation = animation
    self.id = id
//    _zIndex = zIndex
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
            onDragChanged(id, $0, size)
            zIndex = 1
            mouseDown = true
          })
          .onEnded {
            zIndex = 0
            onDragEnded(id, $0, size)
            mouseDown = false
          }
      )
      .gesture(TapGesture().modifiers(.command)
        .onEnded({ _ in
          onClick(id, .command)
        })
      )
      .gesture(TapGesture().modifiers(.shift)
        .onEnded({ _ in
          onClick(id, .shift)
        })
      )
      .gesture(TapGesture()
        .onEnded({ _ in
          isFocused = true
          onClick(id, .empty)
        })
      )
      .focusable()
      .focused($isFocused)
      .enableInjection()
  }
}

