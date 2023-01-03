import SwiftUI



struct LegacyEditableVStack<Data, ID, Content>: View where Content: View,
                                                     Data: RandomAccessCollection,
                                                     Data: MutableCollection,
                                                     Data.Element: Identifiable,
                                                     Data.Index: Hashable,
                                                     ID: Hashable {
  @ObserveInjection var inject
  private enum DropIndex {
    case up(Data.Element.ID)
    case down(Data.Element.ID)
  }
  @Binding private(set) var data: Data
  private(set) var id: KeyPath<Data.Element, ID>
  @ObservedObject private(set) var responderChain: ResponderChain = .shared
  private(set) var namespace: Namespace.ID?
  private(set) var onDelete: ((_ indexSet: IndexSet) -> Void)? = nil
  private(set) var onMove: (_ indexSet: IndexSet, _ toIndex: Int) -> Void
  private(set) var content: (Binding<Data.Element>) -> Content

  @GestureState private var dragState = MoveState<Data.Element>.inactive
  @State private var draggedElement: Data.Element?
  @State private var height: CGFloat = 0
  @State private var dropIndex: DropIndex?

  var body: some View {
    ForEach($data, id: id) { element in
      VStack(spacing: 0) {
        ZStack {
          VStack {
            switch dropIndex {
            case .up(let identifier):
              RoundedRectangle(cornerRadius: 1)
                 .fill(Color.accentColor)
                 .frame(height: 2)
                 .opacity(identifier == element.id ? 1.0 : 0.0)
               Spacer()
            case .down(let identifier):
              Spacer()
              RoundedRectangle(cornerRadius: 1)
                 .fill(Color.accentColor)
                 .frame(height: 2)
                 .opacity(identifier == element.id ? 1.0 : 0.0)
            case .none:
              Spacer()
            }
          }

          GeometryReader { proxy in
            if draggedElement?.id == element.id {
              content(element)
                .contentShape(.dragPreview, Circle(), eoFill: true)
                .offset(withAnimation { dragState.offset(for: element.id) })
                .scaleEffect(withAnimation { dragState.scaleFactor(for: element.id) })
                .zIndex(withAnimation { dragState.zIndex(for: element.id) })
                .onAppear {
                  height = proxy.size.height
                }
            }

          }
          content(element)
            .gesture(
              DragGesture()
                .updating($dragState) { value, state, transaction in
                  state = .dragging(draggedElementID: element.id,
                                    translation: value.translation)
                }.onChanged({ value in
                  draggedElement = element.wrappedValue
                  guard let currentIndex = data.firstIndex(where: { $0.id == element.id }) as? Int else { return }

                  let newIndex = calculateNewIndex(value, currentIndex: currentIndex)
                  if newIndex > currentIndex {
                    let constrained = max(newIndex - 1, 0)
                    dropIndex = .down(data[constrained as! Data.Index].id)
                  } else if newIndex < currentIndex {
                    dropIndex = .up(data[newIndex as! Data.Index].id)
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
    }
    .onDeleteCommand {
      let responders = responderChain.responders
        .filter { responder in
          responder.namespace != .none &&
          responder.namespace == namespace
        }
      var indexes = [Int]()
      for (offset, responder) in responders.enumerated() {
        if responder.isFirstReponder || responder.isSelected {
          indexes.append(offset)
          responderChain.remove(responder)
        }
      }
      withAnimation(.interactiveSpring()) {
        onDelete?(IndexSet(indexes))
      }
    }
    .enableInjection()
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
