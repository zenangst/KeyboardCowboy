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

enum EditableStackFocus<Identifier>: Hashable where Identifier: Hashable,
                                                    Identifier: Equatable {
  case focused(Identifier)
}

private class EditableSelectionManager<Element>: ObservableObject where Element: Identifiable,
                                                                        Element: Equatable,
                                                                        Element: Hashable {
  var selections = Set<Element.ID>() {
    willSet { if selections != newValue { objectWillChange.send() } }
  }
}

class EditableFocusManager<Element>: ObservableObject where Element: Equatable,
                                                            Element: Hashable,
                                                            Element: CustomStringConvertible {
  var focus: EditableStackFocus<Element>?
  {
    willSet {
      objectWillChange.send()
    }
  }

  func publishUpdate(_ elementId: Element) {
    focus = .focused(elementId)
    FocusableProxy<Element>.post(elementId)
  }
}

private class EditableDragManager<Element>: ObservableObject where Element: Identifiable,
                                                                   Element: Hashable {
  var dragInfo: EditableDragInfo = .init(indexes: [], dragIndex: nil)
  var move: EditableMoveInstruction? {
    willSet { objectWillChange.send() }
  }
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

  var focus: FocusState<EditableStackFocus<Data.Element.ID>?>?
  @Binding var data: Data

  fileprivate var focusManager: EditableFocusManager<Data.Element.ID>
  fileprivate var selectionManager: EditableSelectionManager<Data.Element> = .init()
  fileprivate var dragManager: EditableDragManager<Data.Element> = .init()

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
       focusManager: EditableFocusManager<Data.Element.ID> = .init(),
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
    self.focusManager = focusManager
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
       focusManager: EditableFocusManager<Data.Element.ID> = .init(),
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
    self.focusManager = focusManager
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
        clickableView(element, index: index) { element in
          content(element, index)
        }
      }
    }
  }

  @ViewBuilder
  private func axesView<Content: View>(_ data: Binding<Data>, content: @escaping (Binding<Data.Element>, Int) -> Content) -> some View {
    AxesView(configuration.axes,
             lazy: configuration.lazy,
             spacing: configuration.spacing) {
      ForEach(Array(zip(data.indices, data)), id: \.1.id) { offset, element in
        content(element, offset)
          .onDrag({
            let from: [Int]
            if !selectionManager.selections.contains(element.id) {
              selectionManager.selections = []
              from = [offset]
            } else if !selectionManager.selections.isEmpty {
              from = data.indices.filter({ selectionManager.selections.contains(data[$0].id) })
            } else {
              from = [offset]
            }

            dragManager.dragInfo = .init(indexes: from, dragIndex: offset)

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
            EditableDragPreview(
              config: configuration,
              content: { content(element, offset) },
              selections: selectionManager.selections.count)
          })
          .onDrop(of: dropDelegates.flatMap(\.uttypes) + configuration.uttypes,
                  delegate: EditableDropDelegateManager(dropDelegates + [
                    EditableInternalDropDelegate(dropIndex: offset, manager: dragManager,
                                                 uttypes: configuration.uttypes,
                                                 onMove: onMove)
                  ]))
          .id(element.id)
      }
      .onDeleteCommand {
        guard let onDelete else { return }
        if !selectionManager.selections.isEmpty {
          let indexes = selectionManager.selections.compactMap { selection in
            data.firstIndex(where: { $0.id == selection } )
          }
          onDelete(IndexSet(indexes))
        } else if case .focused(let id) = focusManager.focus,
                  let index = data.firstIndex(where: { $0.id == id }) {
          onDelete(IndexSet(integer: index))
        }
      }
    }
  }

  @ViewBuilder
  private func clickableView<Content: View>(_ element: Binding<Data.Element>,
                                              index currentIndex: Int,
                                              content: @escaping (Binding<Data.Element>) -> Content) -> some View {
    EditableClickView(element.wrappedValue, index: currentIndex, content: { content(element) }, onClick: handleClick)
      .overlay(EditableFocusView(manager: focusManager, id: element.id,
                                 configuration: configuration, onKeyDown: { onKeyDown(index: currentIndex, keyCode: $0, modifiers: $1) }))
    .overlay(EditableSelectionOverlayView(manager: selectionManager, element: element.wrappedValue, configuration: configuration))
    .overlay(alignment: overlayAlignment(currentIndex: currentIndex),
             content: {
      EditableDropIndicatorOverlayView(
        dragManager: dragManager,
        selectionManager: selectionManager,
        configuration: configuration,
        currentIndex: currentIndex,
        element: element.wrappedValue,
        elementCount: elementCount)
    })
    .id(element.id)
  }

  private func overlayAlignment(currentIndex: Int) -> Alignment {
    guard let move = dragManager.move else { return .top }
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
                           modifier: EditableClickModifier) {
    focusManager.focus = .focused(element.id)
    focusManager.publishUpdate(element.id)
    switch modifier {
    case .empty:
      selectionManager.selections = []
    case .command:
      onTapWithCommandModifier(element.id)
    case .shift:
      onTapWithShiftModifier(element.id)
    }

    self.onClick(element.id, index)
  }

  private func onKeyDown(index: Int,
                         keyCode: Int,
                         modifiers: NSEvent.ModifierFlags) {
    switch keyCode {
    case kVK_ANSI_A:
      if modifiers.contains(.command) {
        selectionManager.selections = Set(data.map(\.id))
      }
    case kVK_Escape:
      selectionManager.selections = []
    case kVK_DownArrow, kVK_RightArrow:
      selectionManager.selections = []
      let newIndex = index + 1
      if newIndex >= 0 && newIndex < data.count {
        let elementId = data[newIndex].id
        scrollProxy?.scrollTo(elementId)
        focusManager.publishUpdate(elementId)
      }
    case kVK_UpArrow, kVK_LeftArrow:
      selectionManager.selections = []
      let newIndex = index - 1
      if newIndex >= 0 && newIndex < data.count {
        let elementId = data[newIndex].id
        scrollProxy?.scrollTo(elementId)
        focusManager.publishUpdate(elementId)
      }
    case kVK_Return:
      break
    default:
      break
    }
  }

  private func onTapWithCommandModifier(_ elementId: Data.Element.ID) {
    if selectionManager.selections.contains(elementId) {
      selectionManager.selections.remove(elementId)
    } else {
      selectionManager.selections.insert(elementId)
    }
  }

  private func onTapWithShiftModifier(_ elementId: Data.Element.ID) {
    if selectionManager.selections.contains(elementId) {
      selectionManager.selections.remove(elementId)
    } else {
      selectionManager.selections.insert(elementId)
    }

    if case .focused(let currentElement) = focusManager.focus {
      let alreadySelected = selectionManager.selections.contains(elementId)
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
          if selectionManager.selections.contains(element.id) {
            selectionManager.selections.remove(element.id)
          }
        } else {
          if !selectionManager.selections.contains(element.id) {
            selectionManager.selections.insert(element.id)
          }
        }
      }
    }
  }
}

private struct EditableFocusView<Identifier>: View where Identifier: Hashable,
                                                         Identifier: CustomStringConvertible {

  @ObservedObject var manager: EditableFocusManager<Identifier>
  @FocusState var isFocused: Bool
  let id: Identifier
  let configuration: EditableStackConfiguration
  let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  internal init(manager: EditableFocusManager<Identifier>, id: Identifier, configuration: EditableStackConfiguration, onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.manager = manager
    self.id = id
    self.configuration = configuration
    self.onKeyDown = onKeyDown
  }

  var body: some View {
    FocusableProxy(id: id,
                   isFocused: Binding<Bool>(get: { isFocused }, set: { isFocused = $0 }),
                   onKeyDown: onKeyDown)
      .overlay(
        RoundedRectangle(cornerRadius: configuration.cornerRadius)
          .strokeBorder(isFocused ? configuration.selectedColor.opacity(0.1) : Color.clear,
                        lineWidth: 1)
          .shadow(color: isFocused ? configuration.selectedColor.opacity(0.8) : Color(.sRGBLinear, white: 0, opacity: 0.33),
                  radius: isFocused ? 1.0 : 0.0)
          .allowsHitTesting(false)
          .padding(-1)
      )
      .onChange(of: manager.focus) { newValue in
        if newValue == .focused(id) {
          isFocused <- true
        }
      }
      .onAppear {
        if manager.focus == .focused(id) {
          isFocused <- true
        }
      }
      .allowsHitTesting(false)
      .focused($isFocused)
      .id(id)
  }
}

private struct EditableSelectionOverlayView<Element>: View where Element: Hashable,
                                                                 Element: Identifiable {
  @ObservedObject var manager: EditableSelectionManager<Element>
  let element: Element
  let configuration: EditableStackConfiguration

  var body: some View {
    configuration.selectedColor
      .cornerRadius(configuration.cornerRadius)
      .opacity(manager.selections.contains(element.id) ? 0.2 : 0.0)
      .allowsHitTesting(false)
  }
}

private struct EditableDropIndicatorOverlayView<Element>: View where Element: Hashable,
                                                                     Element: Identifiable {
  @ObservedObject var dragManager: EditableDragManager<Element>
  let selectionManager: EditableSelectionManager<Element>
  let configuration: EditableStackConfiguration
  let currentIndex: Int
  let element: Element
  let elementCount: Int

  var body: some View {
    if let move = dragManager.move {
      RoundedRectangle(cornerRadius: configuration.cornerRadius)
        .fill(configuration.selectedColor)
        .frame(maxWidth: configuration.axes == .horizontal ? 2.0 : nil,
               maxHeight: configuration.axes == .vertical ? 2.0 : nil)
        .opacity(
          (move.to == currentIndex || move.to == currentIndex + 1
           && currentIndex == elementCount - 1) &&
          !selectionManager.selections.contains(element.id)
          ? 0.75 : 0.0)
        .allowsHitTesting(false)
    } else {
      EmptyView()
    }
  }
}

private struct EditableDragPreview<Content>: View where Content: View {
  let config: EditableStackConfiguration
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
              .background(Color.red.cornerRadius(config.cornerRadius))
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

private struct EditableInternalDropDelegate<Element>: EditableDropDelegate where Element: Identifiable,
                                                                                 Element: Hashable {
  let uttypes: [String]
  let dropIndex: Int
  let onMove: ((_ indexSet: IndexSet, _ toIndex: Int) -> Void)?
  let manager: EditableDragManager<Element>

  init(dropIndex: Int,
       manager: EditableDragManager<Element>,
       uttypes: [String],
       onMove: ((_ indexSet: IndexSet, _ toIndex: Int) -> Void)?) {
    self.manager = manager
    self.uttypes = uttypes
    self.dropIndex = dropIndex
    self.onMove = onMove
  }

  // MARK: Private methods

  private func reset() {
    manager.dragInfo = .init(indexes: [], dragIndex: nil)
    manager.move = nil
  }

  // MARK: DropDelegate

  func dropEntered(info: DropInfo) {
    guard onMove != nil, !manager.dragInfo.indexes.isEmpty,
          let dragIndex = manager.dragInfo.dragIndex,
          manager.dragInfo.dragIndex != dropIndex else {
      return
    }

    let from = manager.dragInfo.indexes
    manager.move <- .init(from: IndexSet(from), to: dropIndex > dragIndex ? dropIndex + 1 : dropIndex)
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    DropProposal(operation: .move)
  }

  func dropExited(info: DropInfo) {
    manager.move <- nil
  }

  func performDrop(info: DropInfo) -> Bool {
    guard let onMove, let move = manager.move else {
      return false
    }
    defer { reset() }
    onMove(move.from, move.to)
    return true
  }
}

enum EditableClickModifier {
  case command, shift, empty
}

struct EditableClickView<Element, Content>: View where Content : View,
                                                     Element: Hashable,
                                                     Element: Identifiable,
                                                     Element.ID: Hashable,
                                                     Element.ID: CustomStringConvertible {
  private let index: Int
  @ViewBuilder
  private let content: () -> Content
  private let element: Element
  private let onClick: (Element, Int, EditableClickModifier) -> Void

  init(_ element: Element, index: Int,
       @ViewBuilder content: @escaping () -> Content,
       onClick: @escaping (Element, Int, EditableClickModifier) -> Void) {
    self.element = element
    self.index = index
    self.content = content
    self.onClick = onClick
  }

  var body: some View {
    content()
      .gesture(TapGesture().modifiers(.command)
        .onEnded({ _ in
          onClick(element, index, .command)
        })
      )
      .gesture(TapGesture().modifiers(.shift)
        .onEnded({ _ in
          onClick(element, index, .shift)
        })
      )
      .gesture(TapGesture()
        .onEnded({ _ in
          onClick(element, index, .empty)
        })
      )
    }
}
