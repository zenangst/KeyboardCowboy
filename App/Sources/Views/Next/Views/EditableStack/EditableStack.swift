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

  private let mainAnimation = Animation.default.speed(2.5)
  private let proxyAnimation = Animation.default.speed(1.5)
  private let id: KeyPath<Data.Element, Data.Element.ID>
  private let content: (Binding<Data.Element>) -> Content
  private let cornerRadius: Double
  private let spacing: CGFloat?
  private let axes: Axis.Set
  private let lazy: Bool
  private let elementCount: Int
  private let onSelection: (Set<Data.Element.ID>) -> Void
  private let onMove: (_ indexSet: IndexSet, _ toIndex: Int) -> Void
  private let onDelete: (_ indexSet: IndexSet) -> Void

  @State private var dragProxy: CGSize = .zero
  @State private var animating: Double = .random(in: 0...100)
  @State private var selections = Set<Data.Element.ID>() {
    didSet { onSelection(selections) }
  }
  @State private var draggingElementId: Data.Element.ID?
  @State private var draggingElementIndex: Int?
  @State private var newIndex: Int = -1
  @State private var mouseDown: Bool = false

  init(_ data: Binding<Data>,
       axes: Axis.Set = .vertical,
       lazy: Bool = false,
       spacing: CGFloat? = nil,
       id: KeyPath<Data.Element, Data.Element.ID> = \.id,
       cornerRadius: Double = 8,
       onSelection: @escaping ((Set<Data.Element.ID>) -> Void) = { _ in },
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
    self.elementCount = data.count
    self.onMove = onMove
    self.onDelete = onDelete
    self.onSelection = onSelection
  }

  var body: some View {
    axesView { element, index in
      interactiveView(element, index: index) { element in
        content(element)
      }
    }
    .enableInjection()
  }

  @ViewBuilder
  private func axesView<Content: View>(content: @escaping (Binding<Data.Element>, Int) -> Content) -> some View {
    AxesView(axes, lazy: lazy, spacing: spacing) {
      ForEach($data, id: id) { element in
        let index = data.firstIndex(of: element.wrappedValue) ?? 0
        content(element, index)
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
  }

  @ViewBuilder
  private func interactiveView<Content: View>(_ element: Binding<Data.Element>,
                                              index currentIndex: Int,
                                              content: @escaping (Binding<Data.Element>) -> Content) -> some View {
    InteractiveView(
      animation: mainAnimation,
      id: element.id,
      index: currentIndex,
      content: { content(element) },
      overlay: {
        Color.accentColor
          .opacity(selections.contains(element.id) ? 0.2 : 0.0)
          .cornerRadius(cornerRadius)
          .allowsHitTesting(false)
      },
      onClick: onClick,
      onKeyDown: onKeyDown,
      onDragChanged: onDragChanged,
      onDragEnded: onDragEnded
    )
    .offset(calculateOffset(elementID: element.id,
                            currentIndex: currentIndex))
    .animation(proxyAnimation, value: mouseDown)
    .overlay(alignment: currentIndex >= newIndex ? .top : .bottom, content: {
      dropIndicatorOverlay(elementId: element.id,
                           currentIndex: currentIndex,
                           newIndex: newIndex,
                           elementCount: elementCount)
    })
    .focused($focus, equals: .focused(element.wrappedValue.id))
  }

  private func onClick(elementId: Data.Element.ID,
                       index: Int,
                       modifier: InteractiveViewModifier) {
    switch modifier {
    case .empty:
      selections = []
      focus = .focused(elementId)
    case .command:
      focus = .focused(elementId)
      onTapWithCommandModifier(elementId)
    case .shift:
      focus = .focused(elementId)
      onTapWithShiftModifier(elementId)
    }
  }

  private func onDragChanged(elementId: Data.Element.ID,
                             index currentIndex: Int,
                             value: GestureStateGesture<DragGesture, CGSize>.Value,
                             size: CGSize) {
    if draggingElementId != elementId {
      draggingElementId = elementId
      draggingElementIndex = currentIndex
    }

    dragProxy = value.translation

    let elementCount = data.count

    guard elementCount != selections.count else { return }

    let newIndex = max(min(calculateNewIndex(value, size: size, currentIndex: currentIndex), elementCount), 0)

    if self.newIndex != newIndex {
      self.newIndex = newIndex
    }

    if !selections.contains(elementId) {
      selections.removeAll()
    }

    if mouseDown == false {
      mouseDown = true
    }
  }

  private func onDragEnded(elementId: Data.Element.ID,
                           index currentIndex: Int,
                           value: GestureStateGesture<DragGesture, CGSize>.Value,
                           size: CGSize) {
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
      mouseDown = false
      onMove(indexSet, newIndex)
      self.newIndex = -1
      self.dragProxy = .zero
      self.draggingElementId = nil
      self.draggingElementIndex = nil
    }
  }

  private func onKeyDown(elementId: Data.Element.ID,
                         keyCode: Int,
                         modifiers: NSEvent.ModifierFlags) {
    guard case .focused = focus,
          let index = draggingElementIndex else { return }
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

  @ViewBuilder
  private func dropIndicatorOverlay(elementId: Data.Element.ID,
                                    currentIndex: Int,
                                    newIndex: Int,
                                    elementCount: Int) -> some View {
    if let draggingElementIndex {
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(Color.accentColor)
        .frame(maxWidth: axes == .horizontal ? 2.0 : nil,
               maxHeight: axes == .vertical ? 2.0 : nil)
        .opacity(draggingElementIndex != currentIndex &&
                 (newIndex == currentIndex || newIndex == currentIndex + 1
                  && currentIndex == elementCount - 1) &&
                 !selections.contains(elementId)
                 ? 0.75 : 0.0)
        .allowsHitTesting(false)
    } else {
      EmptyView()
    }
  }

  private func calculateOffset(elementID: Data.Element.ID, currentIndex: Int) -> CGSize {
    guard let draggingElementIndex, draggingElementId != nil else {
      return .zero
    }
    let isProxyItem = draggingElementId != nil &&
      elementID != draggingElementId &&
      selections.contains(elementID) &&
      dragProxy != .zero
    let delta = abs(draggingElementIndex - currentIndex)
    return CGSize(width: isProxyItem ? dragProxy.width : 0,
                  height: isProxyItem ?
                  (currentIndex > draggingElementIndex)
                  ? (dragProxy.height - (75.0 * CGFloat(delta)))
                  : (dragProxy.height + (75.0 * CGFloat(delta))) : 0.0)
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
