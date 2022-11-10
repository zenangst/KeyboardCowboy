import Carbon
import SwiftUI

struct EditableVStack<Data, ID, Content>: View where Content: View,
                                                     Data: RandomAccessCollection,
                                                     Data: MutableCollection,
                                                     Data.Element: Identifiable,
                                                     Data.Element: Hashable,
                                                     Data.Index: Hashable,
                                                     ID: Hashable {
  enum Focus: Hashable {
    case focused(Data.Element)
  }

  private enum DropIndex {
    case up(Data.Element.ID)
    case down(Data.Element.ID)
  }


  @ObserveInjection var inject
  @Binding private(set) var data: Data
  @FocusState var focus: Focus?

  private let id: KeyPath<Data.Element, ID>
  private let content: (Binding<Data.Element>) -> Content
  private let cornerRadius: Double

  @GestureState private var dragState = MoveState<Data.Element>.inactive
  @State private var height: CGFloat = 0
  @State private var draggedElement: Data.Element?
  @State private var dropIndex: DropIndex?
  @State private var selections = Set<Data.Element>()

  init(data: Binding<Data>,
       id: KeyPath<Data.Element, ID>,
       cornerRadius: Double,
       content: @escaping (Binding<Data.Element>) -> Content) {
    _data = data
    self.id = id
    self.content = content
    self.cornerRadius = cornerRadius
  }

  var body: some View {
    ForEach($data, id: id) { element in
      let isDragging = draggedElement?.id == element.id
      ZStack {
        GeometryReader { proxy in
          draggableView(element, proxy: proxy)
            .opacity(isDragging ? 0.7 : 0.0)
        }

        ElementView(cornerRadius: cornerRadius,
                    onKeyDown: { value, modifier in
          switch value {
          case kVK_Escape:
            selections = []
            focus = nil
          case kVK_DownArrow, kVK_RightArrow:
            break
          case kVK_UpArrow, kVK_LeftArrow:
            break
          default:
            break
          }
        }) {
          content(element)
        }
        .overlay(overlayView(element))
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
          .onEnded({ _ in onTapWithShiftModifier(element.wrappedValue) })
        )
        .gesture(TapGesture().onEnded { _ in onTap(element.wrappedValue) })
        .focused($focus, equals: .focused(element.wrappedValue))
      }
      dropIndexView(element)
    }
    .enableInjection()
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
        .opacity(selections.contains(element.wrappedValue) ? 0.1 : 0.0)
        .cornerRadius(cornerRadius)
    }
  }

  private func dropIndexView(_ element: Binding<Data.Element>) -> some View {
    VStack {
      switch dropIndex {
      case .up(let identifier):
        RoundedRectangle(cornerRadius: 1)
          .fill(Color.accentColor)
          .frame(height: 2)
          .opacity(identifier == element.id ? 1.0 : 0.0)
      case .down(let identifier):
        RoundedRectangle(cornerRadius: 1)
          .fill(Color.accentColor)
          .frame(height: 2)
          .opacity(identifier == element.id ? 1.0 : 0.0)
      case .none:
        Spacer()
          .frame(height: 2)
      }

    }
    .zIndex(withAnimation { dragState.zIndex(for: element.wrappedValue) })
  }

  private func onDragChange(element: Binding<Data.Element>,
                            value: GestureStateGesture<DragGesture, MoveState<Data.Element>>.Value) {
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
  }

  private func draggableView(_ element: Binding<Data.Element>,
                     proxy: GeometryProxy) -> some View {
    content(element)
      .contentShape(.dragPreview, Circle(), eoFill: true)
      .offset(withAnimation { dragState.offset(for: element.wrappedValue) })
      .scaleEffect(withAnimation { dragState.scaleFactor(for: element.wrappedValue) })
      .zIndex(withAnimation { dragState.zIndex(for: element.wrappedValue) } )
      .onAppear {
        height = proxy.size.height
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

struct ElementView<Content>: View where Content: View {
  @State var isFocused: Bool = false

  private let content: () -> Content
  private let cornerRadius: Double
  private var onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(cornerRadius: Double,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void,
       content: @escaping () -> Content) {
    self.content = content
    self.onKeyDown = onKeyDown
    self.cornerRadius = cornerRadius
  }

  var body: some View {
    FocusableView($isFocused, onKeyDown: onKeyDown, content: content)
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.accentColor, lineWidth: 3)
          .opacity( isFocused  ? 0.3 : 0.0 )
      )
  }
}
