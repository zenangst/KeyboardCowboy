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
    case focused(Data.Element)
  }

  private enum DropIndex {
    case up(Data.Element.ID)
    case down(Data.Element.ID)
  }

  @Environment(\.isFocused) var isFocused
  @ObserveInjection var inject
  @Binding private(set) var data: Data
  @FocusState var focus: Focus?

  private let id: KeyPath<Data.Element, Data.Element.ID>
  private let content: (Binding<Data.Element>) -> Content
  private let cornerRadius: Double
  private let spacing: CGFloat?
  private let axes: Axis.Set
  private let lazy: Bool

  @GestureState private var dragState = MoveState<Data.Element>.inactive
  @State private var size: Double = 0
  @State private var draggedElement: Data.Element?
  @State private var dropIndex: DropIndex?
  @State private var selections = Set<Data.Element>()

  init(_ data: Binding<Data>,
       axes: Axis.Set = .vertical,
       lazy: Bool = false,
       spacing: CGFloat? = nil,
       id: KeyPath<Data.Element, Data.Element.ID> = \.id,
       cornerRadius: Double = 8,
       content: @escaping (Binding<Data.Element>) -> Content) {
    _data = data
    self.id = id
    self.axes = axes
    self.content = content
    self.cornerRadius = cornerRadius
    self.lazy = lazy
    self.spacing = spacing
  }

  var body: some View {
    AxesView(axes, lazy: lazy, spacing: spacing) {
      ForEach($data, id: id) { element in
        let isDragging = draggedElement?.id == element.id
        ZStack {
          ElementView(id: element.id,
                      cornerRadius: cornerRadius,
                      onKeyDown: onKeyDown(_:modifiers:)) { content(element) }
            .overlay(ZStack {
              dropIndexView(element)
              overlayView(element)
            })
            .opacity(isDragging ? 0.0 : 1.0)
            .simultaneousGesture(
              DragGesture()
                .updating($dragState) { value, state, transaction in
                  state = .dragging(draggedElement: element.wrappedValue,
                                    translation: value.translation)
                }
                .onChanged { value in
                  onDragChange(element: element, value: value)
                }
                .onEnded { value in
                  withAnimation(.interactiveSpring()) {
                    draggedElement = nil
                    dropIndex = nil
                  }
                }
            )
            .gesture(TapGesture().modifiers(.command)
              .onEnded({ _ in onTapWithCommandModifier(element.wrappedValue) })
            )
            .gesture(TapGesture().modifiers(.shift)
              .onEnded({ _ in
                focus = .focused(element.wrappedValue)
                onTapWithShiftModifier(element.wrappedValue)
              })
            )
            .gesture(TapGesture().onEnded { _ in onTap(element.wrappedValue) })
            .focused($focus, equals: .focused(element.wrappedValue))

          DraggableView(element: element.wrappedValue,
                        axes: axes,
                        state: dragState,
                        isDragging: Binding<Bool>(get: { isDragging }, set: { _ in }),
                        size: $size,
                        content: { content(element) })
        }
        .zIndex(isDragging ? 2: 0)
      }
    }
    .onChange(of: isFocused, perform: { newValue in
      Swift.print("isFocused: \(newValue):\(#line)")
    })
    .enableInjection()
  }

  private func onKeyDown(_ keyCode: Int, modifiers: NSEvent.ModifierFlags) {
    guard case .focused(let currentElement) = focus,
          let index = data.firstIndex(of: currentElement) else { return }
    switch keyCode {
    case kVK_Escape:
      selections = []
      focus = nil
    case kVK_DownArrow, kVK_RightArrow:
      let newIndex = index + 1
      if newIndex < data.count {
        let newElement = data[newIndex]
        let notification = FocusableNSView.becomeFirstResponderNotification(newElement.id)
        NotificationCenter.default.post(name: notification, object: nil)
        focus = .focused(newElement)
      }
    case kVK_UpArrow, kVK_LeftArrow:
      let newIndex = index - 1
      if newIndex >= 0 {
        let newElement = data[newIndex]
        let notification = FocusableNSView.becomeFirstResponderNotification(newElement.id)
        NotificationCenter.default.post(name: notification, object: nil)
        focus = .focused(newElement)
      }
    case kVK_Return:
      break
    default:
      break
    }
  }

  private func onTap(_ element: Data.Element) {
    focus = .focused(element)
    selections = Set<Data.Element>(arrayLiteral: element)
  }

  private func onTapWithCommandModifier(_ element: Data.Element) {
    if selections.contains(element) {
      selections.remove(element)
    } else {
      selections.insert(element)
    }
    focus = .focused(element)
  }

  private func onTapWithShiftModifier(_ element: Data.Element) {
    if selections.contains(element) {
      selections.remove(element)
    } else {
      selections.insert(element)
    }

    if case .focused(let currentElement) = focus {
      let alreadySelected = selections.contains(element)
      guard var startIndex = data.firstIndex(of: currentElement),
            var endIndex = data.firstIndex(of: element) else {
              return
            }
      if endIndex < startIndex {
        let copy = startIndex
        startIndex = endIndex
        endIndex = copy
      }

      data[startIndex...endIndex].forEach { element in
        if !alreadySelected {
          if selections.contains(element) {
            selections.remove(element)
          }
        } else {
          if !selections.contains(element) {
            selections.insert(element)
          }
        }
      }
    }

    focus = .focused(element)
  }

  private func overlayView(_ element: Binding<Data.Element>) -> some View {
    ZStack {
      Color.accentColor
        .opacity(selections.contains(element.wrappedValue) ? 0.2 : 0.0)
        .cornerRadius(cornerRadius)
    }
  }

  private func dropIndexView(_ element: Binding<Data.Element>) -> some View {
    internalAxesView {
      switch axes {
      case .horizontal:
        switch dropIndex {
        case .up(let identifier):
          RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor)
            .frame(width: 2)
            .opacity(identifier == element.id ? 1.0 : 0.0)
          Spacer()
        case .down(let identifier):
          Spacer()
          RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor)
            .frame(width: 2)
            .opacity(identifier == element.id ? 1.0 : 0.0)
        case .none:
          Spacer()
            .frame(width: 2)
        }
      case .vertical:
        switch dropIndex {
        case .up(let identifier):
          RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor)
            .frame(height: 2)
            .opacity(identifier == element.id ? 1.0 : 0.0)
          Spacer()
        case .down(let identifier):
          Spacer()
          RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor)
            .frame(height: 2)
            .opacity(identifier == element.id ? 1.0 : 0.0)
        case .none:
          Spacer()
            .frame(height: 2)
        }
      default:
        switch dropIndex {
        case .up(let identifier):
          RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor)
            .frame(height: 2)
            .opacity(identifier == element.id ? 1.0 : 0.0)
          Spacer()
        case .down(let identifier):
          Spacer()
          RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor)
            .frame(height: 2)
            .opacity(identifier == element.id ? 1.0 : 0.0)
        case .none:
          Spacer()
            .frame(height: 2)
        }
      }
    }
    .zIndex(withAnimation { dragState.zIndex(for: element.wrappedValue) })
  }

  @ViewBuilder
  private func internalAxesView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    switch axes {
    case .horizontal:
      HStack {
        content()
      }
    case .vertical:
      VStack {
        content()
      }
    default:
      VStack {
        content()
      }
    }
  }

  private func onDragChange(element: Binding<Data.Element>,
                            value: GestureStateGesture<DragGesture, MoveState<Data.Element>>.Value) {
    draggedElement = element.wrappedValue

    guard let currentIndex = data.firstIndex(where: { $0.id == element.id }) else { return }

    let newIndex = calculateNewIndex(value, currentIndex: currentIndex)
    if newIndex > currentIndex {
      let constrained = max(newIndex - 1, 0)
      dropIndex = .down(data[constrained].id)
    } else if newIndex < currentIndex {
      dropIndex = .up(data[newIndex].id)
    } else {
      dropIndex = .none
    }
  }

  private func calculateNewIndex(_ value: GestureStateGesture<DragGesture, MoveState<Data.Element>>.Value,
                                 currentIndex: Int) -> Int {
    let valueToUse: Double
    switch axes {
    case .horizontal:
      valueToUse = value.translation.width
    case .vertical:
      valueToUse = value.translation.height
    default:
      valueToUse = value.translation.height
    }

    guard valueToUse != 0, size > 0 else {
      return currentIndex
    }

    let divided = (valueToUse + (size / 2)) / size
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


private struct AxesView<Content>: View where Content: View {
  @Environment(\.isFocused) var isFocused
  private let axes: Axis.Set
  private let lazy: Bool
  private let spacing: CGFloat?
  @ViewBuilder
  private let content: () -> Content

  internal init(_ axes: Axis.Set,
                lazy: Bool,
                spacing: CGFloat? = nil,
                @ViewBuilder content: @escaping () -> Content) {
    self.axes = axes
    self.spacing = spacing
    self.content = content
    self.lazy = lazy
  }

  var body: some View {
    switch axes {
    case .vertical:
      if lazy {
        LazyVStack(spacing: spacing, content: content)
      } else {
        VStack(spacing: spacing, content: content)
      }
    case .horizontal:
      if lazy {
        LazyHStack(spacing: spacing, content: content)
      } else {
        HStack(spacing: spacing, content: content)
      }
    default:
      VStack(spacing: spacing, content: content)
    }
  }
}

struct DraggableView<Content, Element>: View where Content: View,
                                                   Element: Identifiable,
                                                   Element: Hashable{
  @Binding var size: Double
  @Binding var isDragging: Bool

  private let axes: Axis.Set
  private let element: Element
  private let state: MoveState<Element>
  private let content: () -> Content

  init(element: Element,
       axes: Axis.Set,
       state: MoveState<Element>,
       isDragging: Binding<Bool>,
       size: Binding<Double>,
       content: @escaping () -> Content) {
    _size = size
    _isDragging = isDragging
    self.axes = axes
    self.content = content
    self.state = state
    self.element = element
  }

  var body: some View {
    GeometryReader { proxy in
      content()
        .contentShape(.dragPreview, Circle(), eoFill: true)
        .offset(withAnimation { state.offset(for: element) })
        .scaleEffect(withAnimation { state.scaleFactor(for: element) })
        .zIndex(withAnimation { state.zIndex(for: element) } )
        .onAppear {
          switch axes {
          case .horizontal:
            size = proxy.size.width
          case .vertical:
            size = proxy.size.height
          default:
            size = proxy.size.height
          }
        }
    }
    .opacity(isDragging ? 0.7 : 0.0)
    .animation(.interactiveSpring(), value: isDragging)
  }
}

struct ElementView<Content>: View where Content: View {
  @State var isFocused: Bool = false

  private let id: CustomStringConvertible
  private let content: () -> Content
  private let cornerRadius: Double
  private var onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(id: CustomStringConvertible,
       cornerRadius: Double,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void,
       content: @escaping () -> Content) {
    self.id = id
    self.content = content
    self.onKeyDown = onKeyDown
    self.cornerRadius = cornerRadius
  }

  var body: some View {
    FocusableView(id: id, isFocused: $isFocused, onKeyDown: onKeyDown, content: content)
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.accentColor, lineWidth: 2)
          .opacity(isFocused  ? 0.3 : 0.0 )
      )

  }
}
