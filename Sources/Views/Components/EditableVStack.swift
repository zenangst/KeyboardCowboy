import SwiftUI

// <Data, ID, Content> where Data : RandomAccessCollection, ID : Hashable

enum MoveState<Element: Identifiable> {
  case inactive
  case dragging(draggedElement: Element, translation: CGSize)

  var element: Element? {
    switch self {
    case .inactive:
      return nil
    case .dragging(let element, _):
      return element
    }
  }

  private func isDraggingElement(_ element: Element) -> Bool {
    if case .dragging(let draggedElement, _) = self,
       draggedElement.id == element.id {
      return true
    }
    return false
  }

  func scaleFactor(for element: Element) -> Double { isDraggingElement(element) ? 1.025 : 1 }

  func zIndex(for element: Element) -> Double { isDraggingElement(element) ? 1 : 0 }

  func offset(for element: Element) -> CGSize {
    if case .dragging(_, let translation) = self,
       isDraggingElement(element) {
      return translation
    }
    return .zero
  }
}

struct EditableVStack<Data, ID, Content>: View where Content: View,
                                                     Data: RandomAccessCollection,
                                                     Data: MutableCollection,
                                                     Data.Element: Identifiable,
                                                     Data.Index: Hashable,
                                                     ID: Hashable {
  enum DropIndex {
    case up(Int)
    case down(Int)
  }
  @Binding var data: Data
  var id: KeyPath<Data.Element, ID>
  var responderChain: ResponderChain = .shared
  var namespace: Namespace.ID?
  var onDelete: ((_ indexSet: IndexSet) -> Void)? = nil
  var onMove: (_ indexSet: IndexSet, _ toIndex: Int) -> Void
  var content: (Binding<Data.Element>) -> Content
  @GestureState var dragState = MoveState<Data.Element>.inactive
  @State var draggedElement: Data.Element?
  @State var height: CGFloat = 0
  @State var dropIndex: DropIndex?

  var body: some View {
    ForEach(Array($data.enumerated()), id: \.element.id) { offset, element in
      VStack(spacing: 0) {
        ZStack {
          VStack {
            switch dropIndex {
            case .up(let index):
              RoundedRectangle(cornerRadius: 1)
                 .fill(Color.accentColor)
                 .frame(height: 2)
                 .opacity(index == offset ? 1.0 : 0.0)
               Spacer()
            case .down(let index):
              Spacer()
              RoundedRectangle(cornerRadius: 1)
                 .fill(Color.accentColor)
                 .frame(height: 2)
                 .opacity(index - 1 == offset ? 1.0 : 0.0)
            case .none:
              Spacer()
            }
          }

          GeometryReader { proxy in
            if draggedElement?.id == element.id {
              content(element)
                .contentShape(.dragPreview, Circle(), eoFill: true)
                .offset(withAnimation { dragState.offset(for: element.wrappedValue) })
                .scaleEffect(withAnimation { dragState.scaleFactor(for: element.wrappedValue) })
                .zIndex(withAnimation { dragState.zIndex(for: element.wrappedValue) })
                .onAppear {
                  height = proxy.size.height
                }
            }

          }
          content(element)
            .gesture(
              DragGesture()
                .updating($dragState) { value, state, transaction in
                  state = .dragging(draggedElement: element.wrappedValue,
                                    translation: value.translation)
                }.onChanged({ value in
                  draggedElement = element.wrappedValue
                  guard let currentIndex = data.firstIndex(where: { $0.id == element.id }) as? Int else { return }

                  let newIndex = calculateNewIndex(value, currentIndex: currentIndex)
                  if newIndex > currentIndex {
                    dropIndex = .down(newIndex)
                  } else if newIndex < currentIndex {
                    dropIndex = .up(newIndex)
                  } else {
                    dropIndex = .none
                  }
                }).onEnded({ value in
                  withAnimation(.interactiveSpring()) {
                    guard let currentIndex = data.firstIndex(where: { $0.id == element.id }) as? Int else { return }

                    let newIndex = calculateNewIndex(value, currentIndex: currentIndex)
                    let indexSet = IndexSet(integer: currentIndex)

                    onMove(indexSet, newIndex)
                    draggedElement = nil
                    dropIndex = nil
                  }
                })
            )
        }
      }
    }.onDeleteCommand {
      let responders = responderChain.responders
        .enumerated()
        .filter { _, responder in
          responder.namespace != .none &&
          responder.namespace == namespace &&
          (responder.isSelected || responder.isFirstReponder)
        }
      responders.forEach { responderChain.remove($0.element) }
      onDelete?(IndexSet(responders.compactMap({ $0.offset })))
    }
  }

  private func calculateNewIndex(_ value: GestureStateGesture<DragGesture, MoveState<Data.Element>>.Value,
                                 currentIndex: Int) -> Int {
    guard value.translation.height != 0, height > 0 else {
      return currentIndex
    }

    let divided = (value.translation.height + (height / 2)) / height
    let flooredValue = floor(divided)
    let roundedValue = round(divided)
    let ceiledValue = ceil(divided)

    if Int(flooredValue) == currentIndex {
      return currentIndex
    }

    let translation: Int
    if ceiledValue == roundedValue {
      translation = Int(ceiledValue)
    } else {
      translation = Int(roundedValue)
    }

    let newIndex = min(max(currentIndex + translation, 0), data.count)
    guard newIndex != currentIndex else {
      return currentIndex
    }

    return newIndex
  }
}
