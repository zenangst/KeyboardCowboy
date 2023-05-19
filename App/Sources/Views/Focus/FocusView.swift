import SwiftUI

enum FocusBackgroundViewStyle {
  case list
  case focusRing
}

struct FocusView<Element>: View where Element: Hashable,
                                      Element: Equatable,
                                      Element: Identifiable,
                                      Element.ID: CustomStringConvertible {

  @ObservedObject var focusPublisher: FocusPublisher<Element>
  @ObservedObject var selectionManager: SelectionManager<Element>
  @FocusState var isFocused: Bool
  @Binding var element: Element
  @Binding var isTargeted: Bool
  let cornerRadius: Double
  let style: FocusBackgroundViewStyle

  init(_ focusPublisher: FocusPublisher<Element>, element: Binding<Element>,
       isTargeted: Binding<Bool>,
       selectionManager: SelectionManager<Element>, cornerRadius: Double,
       style: FocusBackgroundViewStyle) {
    self.focusPublisher = focusPublisher
    self.selectionManager = selectionManager
    _isTargeted = isTargeted
    _element = element
    self.cornerRadius = cornerRadius
    self.style = style
  }

  var body: some View {
    FocusableProxy(element,
                   isFocused: Binding<Bool>(get: { isFocused }, set: { isFocused = $0 }),
                   selectionManager: selectionManager)
      .overlay(
        FocusOverlayView(isFocused: _isFocused, isTargeted: $isTargeted,
                         cornerRadius: cornerRadius,
                         manager: selectionManager, style: style)
      )
      .background(
        FocusBackgroundView(isFocused: _isFocused,
                            isTargeted: $isTargeted,
                            manager: selectionManager,
                            element: element,
                            cornerRadius: cornerRadius,
                            style: style))
      .compositingGroup()
      .focused($isFocused)
  }
}

private struct FocusOverlayView<Element>: View where Element: Hashable, Element: Identifiable {
  @FocusState var isFocused: Bool
  @Binding var isTargeted: Bool
  let cornerRadius: Double
  @ObservedObject var manager: SelectionManager<Element>
  let style: FocusBackgroundViewStyle

  var body: some View {
    Group {
      RoundedRectangle(cornerRadius: cornerRadius + 1.5, style: .continuous)
        .strokeBorder(manager.selectedColor, lineWidth: 1.5)
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .strokeBorder(manager.selectedColor.opacity(0.5), lineWidth: 1.5)
        .padding(1.5)
    }
      .allowsHitTesting(false)
      .opacity(focusOpacity())
  }

  private func focusOpacity() -> Double {
    if isTargeted {
      return 1
    }

    if style == .focusRing && isFocused {
      return 1
    }

    return 0
  }
}

private struct FocusBackgroundView<Element>: View where Element: Hashable, Element: Identifiable {
  @FocusState var isFocused: Bool
  @Binding var isTargeted: Bool
  @ObservedObject var manager: SelectionManager<Element>
  let element: Element
  let cornerRadius: Double
  let style: FocusBackgroundViewStyle

  var body: some View {
    manager.selectedColor
      .cornerRadius(cornerRadius)
      .opacity(focusOpacity())
  }

  private func focusOpacity() -> Double {
    if isTargeted {
      return 0.5
    }

    guard manager.selections.contains(element.id) else {
      return 0
    }

    if style == .focusRing && manager.selections.count <= 1 {
      return 0
    }

    switch (style, isFocused) {
    case (.focusRing, true):
      return 0.2
    case (.focusRing, false):
      return 0.2
    case (.list, true):
      return 0.8
    case (.list, false):
      return 0.3
    }
  }
}

