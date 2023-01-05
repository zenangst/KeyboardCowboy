import Carbon
import SwiftUI

struct EditableStack<Data, Content>: View where Content: View,
                                                Data: RandomAccessCollection,
                                                Data: MutableCollection,
                                                Data.Element: Identifiable,
                                                Data.Element: Hashable,
                                                Data.Index: Hashable,
                                                Data.Index == Int,
                                                Data.Element.ID: CustomStringConvertible {
  enum Focus: Hashable {
    case focused(Data.Element.ID)
  }

  @ObserveInjection var inject
  @Binding var data: Data
  @FocusState var focus: Focus?
  @Environment(\.resetFocus) var resetFocus

  private let id: KeyPath<Data.Element, Data.Element.ID>
  private let content: (Binding<Data.Element>) -> Content
  private let cornerRadius: Double
  private let spacing: CGFloat?
  private let axes: Axis.Set
  private let lazy: Bool
  private let onMove: (_ indexSet: IndexSet, _ toIndex: Int) -> Void
  private let onDelete: (_ indexSet: IndexSet) -> Void

  @State private var dragProxy: CGSize = .zero
  @State private var animating: Double = .random(in: 0...100)
  @State private var selections = Set<Data.Element.ID>()
  @State private var draggingElementId: Data.Element.ID?
  @State private var newIndex: Int = -1

  init(_ data: Binding<Data>,
       axes: Axis.Set = .vertical,
       lazy: Bool = false,
       spacing: CGFloat? = nil,
       id: KeyPath<Data.Element, Data.Element.ID> = \.id,
       cornerRadius: Double = 8,
       onMove: @escaping (_ indexSet: IndexSet, _ toIndex: Int) -> Void,
       onDelete: @escaping (_ indexSet: IndexSet) -> Void = { _ in },
       content: @escaping (Binding<Data.Element>) -> Content) {
    _data = data
    self.id = id
    self.axes = axes
    self.content = content
    self.cornerRadius = cornerRadius
    self.lazy = lazy
    self.spacing = spacing
    self.onMove = onMove
    self.onDelete = onDelete
  }

  var body: some View {
      let mainAnimation = Animation.default.speed(2.5)
      let proxyAnimation = mainAnimation.speed(1.5)
      AxesView(axes, lazy: lazy, spacing: spacing) {
        let elementCount = data.count
        let indexOfDraggedElement = data.firstIndex(where: { $0.id == draggingElementId }) ?? -1
        ForEach($data, id: id) { element in
          let isProxyItem = element.id != draggingElementId
          && selections.contains(element.id)
          && dragProxy != .zero

          let isDraggedItem = element.id == draggingElementId
          let currentIndex = data.firstIndex(where: { $0.id == element.id }) ?? 0
          let delta = abs(indexOfDraggedElement - currentIndex)

          InteractiveView(
            animation: mainAnimation,
            id: element.id,
            currentIndex: currentIndex,
            zIndex: Binding<Double>(get: {
              draggingElementId == element.id ? Double(elementCount) : isProxyItem ? Double(elementCount - delta) : 0.0
            }, set: { _ in }),
            content: content(element),
            overlay: {
              Color.accentColor
                .opacity(selections.contains(element.id) ? 0.2 : 0.0)
                .cornerRadius(cornerRadius)
                .allowsHitTesting(false)
            },
            onClick: { modifier in
              switch modifier {
              case .empty:
                selections = []
                focus = .focused(element.id)
              case .command:
                focus = .focused(element.id)
                onTapWithCommandModifier(element.id)
              case .shift:
                focus = .focused(element.id)
                onTapWithShiftModifier(element.id)
              }
            },
            onKeyDown: onKeyDown,
            onDragChanged: { value, size in
              draggingElementId = element.id
              dragProxy = value.translation

              guard elementCount != selections.count else { return }

              newIndex = max(min(calculateNewIndex(value, size: size, currentIndex: currentIndex), elementCount), 0)

              if !selections.contains(element.id) {
                selections.removeAll()
              }
            },
            onDragEnded: { value, size in
              let newIndex = max(min(calculateNewIndex(value, size: size, currentIndex: currentIndex), elementCount), 0)
              let indexSet: IndexSet

              if !selections.isEmpty {
                let indexes = selections.compactMap { selection in
                  data.firstIndex(where: { $0.id == selection } )
                }
                indexSet = IndexSet(indexes)
              } else {
                indexSet = IndexSet(integer: currentIndex)
              }
              withAnimation {
                onMove(indexSet, newIndex)
                self.newIndex = -1
                self.dragProxy = .zero
                self.draggingElementId = nil
              }
            }
          )
          //        .scaleEffect(isProxyItem ? 0.95 * CGFloat(1/delta) : 1)
          .offset(x: isProxyItem ? dragProxy.width : 0,
                  y: isProxyItem ?
                  (currentIndex > indexOfDraggedElement)
                  ? (dragProxy.height - (75 * CGFloat(delta)))
                  : (dragProxy.height + (75 * CGFloat(delta))) : 0)
          .animation(proxyAnimation, value: dragProxy)
          .opacity(isProxyItem ? 0.8 : isDraggedItem ? 0.9 : 1)
          .overlay(alignment: currentIndex >= newIndex ? .top : .bottom, content: {
            RoundedRectangle(cornerRadius: cornerRadius)
              .fill(Color.accentColor)
              .frame(maxWidth: axes == .horizontal ? 2 : nil,
                     maxHeight: axes == .vertical ? 2 : nil)
              .opacity(indexOfDraggedElement != currentIndex &&
                       (newIndex == currentIndex || newIndex == currentIndex + 1
                        && currentIndex == elementCount - 1) &&
                       !selections.contains(element.id)
                       ? 0.75 : 0)
              .allowsHitTesting(false)
          })
          .focused($focus, equals: .focused(element.wrappedValue.id))
        }
        .onDeleteCommand {
          if !selections.isEmpty {
            let indexes = selections.compactMap { selection in
              data.firstIndex(where: { $0.id == selection } )
            }
            onDelete(IndexSet(indexes))
          } else if case .focused(let id) = focus,
                    let index = data.firstIndex(where: { $0.id == id }) {
            onDelete(IndexSet(integer: index))
          }
        }
      }
      .enableInjection()
  }

  private func onKeyDown(_ keyCode: Int,
                         modifiers: NSEvent.ModifierFlags) {
    guard case .focused(let currentId) = focus,
          let index = data.firstIndex(where: { $0.id == currentId }) else { return }
    switch keyCode {
    case kVK_Escape:
      selections = []
      focus = nil
    case kVK_DownArrow, kVK_RightArrow:
      let newIndex = index + 1
      if newIndex < data.count { focus = .focused(data[newIndex].id) }
      selections = []
    case kVK_UpArrow, kVK_LeftArrow:
      let newIndex = index - 1
      if newIndex >= 0 { focus = .focused(data[newIndex].id) }
      selections = []
    case kVK_Return:
      break
    default:
      break
    }
  }

  private func onTapWithCommandModifier(_ elementId: Data.Element.ID) {
    if selections.contains(elementId) {
      selections.remove(elementId)
    } else {
      selections.insert(elementId)
    }
  }

  private func onTapWithShiftModifier(_ elementId: Data.Element.ID) {
    if selections.contains(elementId) {
      selections.remove(elementId)
    } else {
      selections.insert(elementId)
    }

    if case .focused(let currentElement) = focus {
      let alreadySelected = selections.contains(elementId)
      guard var startIndex = data.firstIndex(where: { $0.id == currentElement }),
            var endIndex = data.firstIndex(where: { $0.id == elementId }) else {
              return
            }
      if endIndex < startIndex {
        let copy = startIndex
        startIndex = endIndex
        endIndex = copy
      }

      data[startIndex...endIndex].forEach { element in
        if !alreadySelected {
          if selections.contains(element.id) {
            selections.remove(element.id)
          }
        } else {
          if !selections.contains(element.id) {
            selections.insert(element.id)
          }
        }
      }
    }
  }

  private func calculateNewIndex(_ value: GestureStateGesture<DragGesture, CGSize>.Value,
                                 size: CGSize,
                                 currentIndex: Int) -> Int {
    let valueToUse: Double
    let sizeValue: CGFloat
    switch axes {
    case .horizontal:
      valueToUse = value.translation.width
      sizeValue = size.width
    case .vertical:
      valueToUse = value.translation.height
      sizeValue = size.height
    default:
      valueToUse = value.translation.height
      sizeValue = size.height
    }

    guard valueToUse != 0, sizeValue > 0 else {
      return currentIndex
    }

    let divided = (valueToUse + (sizeValue / 2)) / sizeValue
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
