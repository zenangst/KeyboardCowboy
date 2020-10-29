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

struct MovableView<Element, Content>: View where Content: View, Element: Hashable {
  typealias DragHandler = (CGSize, Element) -> Void
  let contentView: Content
  let element: Element
  let dragHandler: DragHandler

  @GestureState var dragState = DragState.inactive
  @State private var opacity: Double = 1.0
  @State private var offset: CGSize = .zero
  @State private var scaleFactor: CGFloat = 1.0
  @State private var isMoving: Bool = false

  init(element: Element, dragHandler: @escaping DragHandler, _ contentView: () -> Content) {
    self.dragHandler = dragHandler
    self.element = element
    self.contentView = contentView()
  }

  var body: some View {
    contentView
      .shadow(color: isMoving ? Color.black.opacity(0.25) : .clear ,
              radius: isMoving ? 5 : 0,
              x: 0,
              y: isMoving ? 5 : 0)
      .scaleEffect(withAnimation { self.scaleFactor })
      .opacity(withAnimation { self.isMoving ? 0.8 : 1.0 })
      .offset(withAnimation { self.offset })
      .gesture(
        DragGesture()
          .updating($dragState) { value, state, _ in
            state = .dragging(translation: value.translation)
          }
          .onChanged({ value in
            withAnimation { self.scaleFactor = 1.025 }
            self.isMoving = true
            self.offset.height = value.translation.height
          })
          .onEnded { _ in
            withAnimation {
              self.dragHandler(offset, element)
              self.scaleFactor = 1.0
            }
            self.offset = .zero
            self.isMoving = false
          }
      )
      .zIndex(isMoving ? 2 : 1)
  }
}
