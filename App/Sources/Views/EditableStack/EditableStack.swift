import Carbon
import SwiftUI
import UniformTypeIdentifiers

struct EditableDragInfo: Equatable {
  let indexes: [Int]
  let dragIndex: Int?
}

enum EditableAxis: Equatable {
  case horizontal
  case vertical

  var axisValue: Axis.Set {
    switch self {
    case .horizontal:
      return .horizontal
    case .vertical:
      return .vertical
    }
  }
}

struct EditableStackConfiguration: Equatable {
  let axes: EditableAxis
  let cornerRadius: Double
  let lazy: Bool
  let selectedColor: Color
  let spacing: CGFloat?
  let uttypes: [String]

  internal init(axes: EditableAxis = .vertical,
                cornerRadius: Double = 8,
                lazy: Bool = false,
                selectedColor: Color = Color(.controlAccentColor),
                uttypes: [String] = [UTType.text.identifier],
                spacing: CGFloat? = nil) {
    self.axes = axes
    self.cornerRadius = cornerRadius
    self.lazy = lazy
    self.selectedColor = selectedColor
    self.spacing = spacing
    self.uttypes = uttypes
  }
}

enum EditableStackFocus<Item>: Hashable where Item: Hashable,
                                              Item: Equatable,
                                              Item: Identifiable {
  case focused(Item.ID)
}

struct EditableStack<Data, Content, NoContent>: View where Content: View,
                                                           NoContent: View,
                                                           Data: RandomAccessCollection,
                                                           Data: MutableCollection,
                                                           Data.Element: Equatable,
                                                           Data.Element: Identifiable,
                                                           Data.Element: Hashable,
                                                           Data.Index: Hashable,
                                                           Data.Index == Int,
                                                           Data.Element.ID: CustomStringConvertible {

  @FocusState var focus: EditableStackFocus<Data.Element>?

  @Binding var data: Data

  @State private var selections = Set<Data.Element.ID>() { didSet { onSelection(selections) } }
  @State private var dragInfo: EditableDragInfo = .init(indexes: [], dragIndex: nil)
  @State private var move: EditableMoveInstruction?

  @ViewBuilder
  private let content: (Binding<Data.Element>, Int) -> Content
  @ViewBuilder
  private let emptyView: (() -> NoContent)?
  private let configuration: EditableStackConfiguration
  private let dropDelegates: [any EditableDropDelegate]
  private let elementCount: Int
  private let scrollProxy: ScrollViewProxy?
  private let itemProvider: (([Data.Element]) -> NSItemProvider)?
  private let onClick: (Data.Element.ID, Int) -> Void
  private let onSelection: (Set<Data.Element.ID>) -> Void
  private let onMove: ((_ indexSet: IndexSet, _ toIndex: Int) -> Void)?
  private let onDelete: ((_ indexSet: IndexSet) -> Void)?

  init(_ data: Binding<Data>,
       configuration: EditableStackConfiguration,
       dropDelegates: [any EditableDropDelegate] = [],
       scrollProxy: ScrollViewProxy? = nil,
       itemProvider: (([Data.Element]) -> NSItemProvider)? = nil,
       onClick: @escaping (Data.Element.ID, Int) -> Void = { _ , _ in },
       onSelection: @escaping ((Set<Data.Element.ID>) -> Void) = { _ in },
       onMove: ((_ indexSet: IndexSet, _ toIndex: Int) -> Void)? = nil,
       onDelete: ((_ indexSet: IndexSet) -> Void)? = nil,
       @ViewBuilder content: @escaping (Binding<Data.Element>, Int) -> Content) where NoContent == Never {
    _data = data
    self.configuration = configuration
    self.content = content
    self.dropDelegates = dropDelegates
    self.elementCount = data.count
    self.emptyView = nil
    self.itemProvider = itemProvider
    self.onClick = onClick
    self.onDelete = onDelete
    self.onMove = onMove
    self.onSelection = onSelection
    self.scrollProxy = scrollProxy
  }

  init(_ data: Binding<Data>,
       configuration: EditableStackConfiguration,
       dropDelegates: [any EditableDropDelegate] = [],
       @ViewBuilder emptyView: @escaping () -> NoContent,
       scrollProxy: ScrollViewProxy? = nil,
       id: KeyPath<Data.Element, Data.Element.ID> = \.id,
       itemProvider: (([Data.Element]) -> NSItemProvider)? = nil,
       onClick: @escaping (Data.Element.ID, Int) -> Void = { _ , _ in },
       onSelection: @escaping ((Set<Data.Element.ID>) -> Void) = { _ in },
       onMove: ((_ indexSet: IndexSet, _ toIndex: Int) -> Void)? = nil,
       onDelete: ((_ indexSet: IndexSet) -> Void)? = nil,
       @ViewBuilder content: @escaping (Binding<Data.Element>, Int) -> Content) {
    _data = data
    self.configuration = configuration
    self.content = content
    self.dropDelegates = dropDelegates
    self.elementCount = data.count
    self.emptyView = emptyView
    self.itemProvider = itemProvider
    self.onClick = onClick
    self.onDelete = onDelete
    self.onMove = onMove
    self.onSelection = onSelection
    self.scrollProxy = scrollProxy
  }

  var body: some View {
    if let emptyView, data.isEmpty {
        emptyView()
          .onDrop(of: dropDelegates.flatMap { $0.uttypes },
                  delegate: EditableDropDelegateManager(dropDelegates))
    } else {
      axesView($data) { element, index in
        interactiveView(element, index: index) { element in
          content(element, index)
        }
      }
    }
  }

  @ViewBuilder
  private func axesView<Content: View>(_ data: Binding<Data>,
                                       content: @escaping (Binding<Data.Element>, Int) -> Content) -> some View {
    AxesView(configuration.axes,
             lazy: configuration.lazy,
             spacing: configuration.spacing) {
      ForEach(Array(zip(data.indices, data)), id: \.1.id) { offset, element in
        content(element, offset)
          .onDrag({
            let from: [Int]
            if !selections.contains(element.id) {
              selections = []
              from = [offset]
            } else if !selections.isEmpty {
              from = data.indices.filter({ selections.contains(data[$0].id) })
            } else {
              from = [offset]
            }

            dragInfo = .init(indexes: from, dragIndex: offset)

            if let itemProvider {
              let elements = data.wrappedValue.enumerated()
                .compactMap({
                  if from.contains($0.offset) {
                    return $0.element
                  }
                  return nil
                })
              return itemProvider(elements)
            }

            return .init(object: "" as NSString)
          }, preview: {
            EditableDragPreview(content: { content(element, offset) }, selections: selections.count)
          })
          .onDrop(of: dropDelegates.flatMap(\.uttypes) + configuration.uttypes,
                  delegate: EditableDropDelegateManager(dropDelegates + [
                    EditableInternalDropDelegate(dropIndex: offset, dragInfo: $dragInfo,
                                                 move: $move, uttypes: configuration.uttypes,
                                                 onMove: onMove)
                  ]))
          .focused($focus, equals: .focused(element.id))
          .id(element.id)
      }
      .onDeleteCommand {
        guard let onDelete else { return }
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
      element.wrappedValue,
      index: currentIndex,
      selectedColor: configuration.selectedColor,
      content: { content(element) },
      overlay: { element, _ in
        RoundedRectangle(cornerRadius: configuration.cornerRadius)
          .fill(configuration.selectedColor)
          .opacity(selections.contains(element.id) ? 0.2 : 0.0)
          .allowsHitTesting(false)
      },
      onClick: handleClick,
      onKeyDown: { onKeyDown(index: currentIndex, keyCode: $0, modifiers: $1) }
    )
    .overlay(alignment: overlayAlignment(currentIndex: currentIndex),
             content: { dropIndicatorOverlay(elementId: element.id,
                                             currentIndex: currentIndex,
                                             elementCount: elementCount)
    })
  }

  @ViewBuilder
  private func dropIndicatorOverlay(elementId: Data.Element.ID,
                                    currentIndex: Int,
                                    elementCount: Int) -> some View {
    if let move {
      RoundedRectangle(cornerRadius: configuration.cornerRadius)
        .fill(configuration.selectedColor)
        .frame(maxWidth: configuration.axes == .horizontal ? 2.0 : nil,
               maxHeight: configuration.axes == .vertical ? 2.0 : nil)
        .opacity(
          (move.to == currentIndex || move.to == currentIndex + 1
           && currentIndex == elementCount - 1) &&
          !selections.contains(elementId)
          ? 0.75 : 0.0)
        .allowsHitTesting(false)
    } else {
      EmptyView()
    }
  }

  private func overlayAlignment(currentIndex: Int) -> Alignment {
    guard let move else { return .top }
    let newIndex = move.to
    switch configuration.axes {
    case .horizontal:
      return currentIndex >= newIndex ? .leading : .trailing
    default:
      return currentIndex >= newIndex ? .top : .bottom
    }
  }

  private func handleClick(element: Data.Element,
                           index: Int,
                           modifier: InteractiveViewModifier) {
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

    self.onClick(element.id, index)
  }

  private func onKeyDown(index: Int,
                         keyCode: Int,
                         modifiers: NSEvent.ModifierFlags) {
    guard case .focused = focus else { return }
    switch keyCode {
    case kVK_ANSI_A:
      if modifiers.contains(.command) {
        selections = Set(data.map(\.id))
      }
    case kVK_Escape:
      selections = []
      focus = nil
    case kVK_DownArrow, kVK_RightArrow:
      let newIndex = index + 1
      if newIndex < data.count {
        let elementId = data[newIndex].id
        focus = .focused(elementId)
        scrollProxy?.scrollTo(elementId)
      }
      selections = []
    case kVK_UpArrow, kVK_LeftArrow:
      let newIndex = index - 1
      if newIndex >= 0 {
        let elementId = data[newIndex].id
        focus = .focused(elementId)
          scrollProxy?.scrollTo(elementId)
      }
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
}

private struct EditableDragPreview<Content>: View where Content: View {
  let content: () -> Content
  let selections: Int

  @ViewBuilder
  var body: some View {
      if selections > 1 {
        content()
          .overlay(alignment: .bottomTrailing, content: {
            Text("\(selections)")
              .font(.callout)
              .padding(4)
              .background(Circle().fill(.red))
              .offset(x: 4, y: 4)
          })
          .padding()
      } else {
        content()
      }
  }
}

private struct EditableDropDelegateManager: DropDelegate {
  let delegates: [EditableDropDelegate]

  init(_ delegates: [EditableDropDelegate]) {
    self.delegates = delegates
  }

  func dropEntered(info: DropInfo) {
    delegates(for: info)
      .forEach { $0.dropEntered(info: info) }
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    var result: DropProposal? = nil
    for delegate in delegates(for: info) {
      if let proposal = delegate.dropUpdated(info: info) {
        result = proposal
        break
      }
    }
    return result
  }

  func dropExited(info: DropInfo) {
    delegates(for: info)
      .forEach { $0.dropExited(info: info) }
  }

  func performDrop(info: DropInfo) -> Bool {
    var result: Bool = false
    for delegate in delegates {
      if delegate.performDrop(info: info) {
        result = true
      }
    }
    return result
  }

  func validateDrop(info: DropInfo) -> Bool {
    delegates(for: info)
      .allSatisfy {
        $0.validateDrop(info: info)
      }
  }

  private func delegates(for info: DropInfo) -> [EditableDropDelegate] {
    delegates.filter { info.hasItemsConforming(to: $0.uttypes) }
  }
}

protocol EditableDropDelegate: DropDelegate {
  var uttypes: [String] { get }
}

private struct EditableMoveInstruction: Equatable {
  let from: IndexSet
  let to: Int
}

private struct EditableInternalDropDelegate: EditableDropDelegate {
  let uttypes: [String]
  let dropIndex: Int
  let onMove: ((_ indexSet: IndexSet, _ toIndex: Int) -> Void)?
  @Binding var dragInfo: EditableDragInfo
  @Binding var move: EditableMoveInstruction?

  init(dropIndex: Int,
       dragInfo: Binding<EditableDragInfo>,
       move: Binding<EditableMoveInstruction?>,
       uttypes: [String],
       onMove: ((_ indexSet: IndexSet, _ toIndex: Int) -> Void)?) {
    _dragInfo = dragInfo
    _move = move
    self.uttypes = uttypes
    self.dropIndex = dropIndex
    self.onMove = onMove
  }

  // MARK: Private methods

  private func reset() {
    dragInfo = .init(indexes: [], dragIndex: nil)
    move = nil
  }

  // MARK: DropDelegate

  func dropEntered(info: DropInfo) {
    guard onMove != nil, !dragInfo.indexes.isEmpty,
          let dragIndex = dragInfo.dragIndex,
          dragInfo.dragIndex != dropIndex else {
      return
    }

    let from = dragInfo.indexes
    move = .init(from: IndexSet(from), to: dropIndex > dragIndex ? dropIndex + 1 : dropIndex)
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    DropProposal(operation: .move)
  }

  func dropExited(info: DropInfo) {
    move = nil
  }

  func performDrop(info: DropInfo) -> Bool {
    defer { reset() }

    guard let onMove, let move else {
      return false
    }

    onMove(move.from, move.to)
    return true
  }
}
