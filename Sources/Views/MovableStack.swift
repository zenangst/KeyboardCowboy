import SwiftUI

enum DragState {
  case inactive
  case dragging(translation: CGSize)

  var translation: CGSize {
    switch self {
    case .dragging(let translation):
      return translation
    default:
      return .zero
    }
  }
}

struct MovableStack<Element, Content>: View where Content: View, Element: Hashable {
  enum Axis {
    case vertical
    case horizontal
  }

  typealias DragHandler = (CGSize, Element) -> Void
  let axis: Axis
  let content: Content
  let element: Element
  let dragHandler: DragHandler

  @GestureState var dragState = DragState.inactive
  @State private var opacity: Double = 1.0
  @State private var offset: CGSize = .zero
  @State private var scaleFactor: CGFloat = 1.0
  @State private var isMoving: Bool = false
  @State private var zIndex: Double = 1

  init(axis: Axis = .vertical, element: Element, dragHandler: @escaping DragHandler, content: () -> Content) {
    self.axis = axis
    self.dragHandler = dragHandler
    self.element = element
    self.content = content()
  }

  var body: some View {
    content
      .shadow(color: isMoving ? Color.black.opacity(0.25) : .clear ,
              radius: isMoving ? 5 : 0,
              x: 0,
              y: isMoving ? 5 : 0)
      .scaleEffect(withAnimation { self.scaleFactor })
      .offset(withAnimation { self.offset })
      .gesture(
        DragGesture()
          .updating($dragState) { value, state, _ in
            state = .dragging(translation: value.translation)
          }
          .onChanged({ value in
            withAnimation { self.scaleFactor = 1.025 }
            self.isMoving = true

            switch axis {
            case .horizontal:
              self.offset.width = value.translation.width
            case .vertical:
              self.offset.height = value.translation.height
            }

            self.zIndex = 2
          })
          .onEnded { _ in
            withAnimation {
              self.dragHandler(offset, element)
              self.scaleFactor = 1.0
              self.offset = .zero
            }
            self.isMoving = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              self.zIndex = 1
            }
          }
      )
      .zIndex(withAnimation { self.zIndex })
  }
}
