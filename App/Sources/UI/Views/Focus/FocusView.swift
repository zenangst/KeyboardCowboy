import SwiftUI

enum FocusBackgroundViewStyle {
  case list
  case focusRing
}

struct FocusView<Element>: View where Element: Hashable,
                                      Element: Equatable,
                                      Element: Identifiable,
                                      Element.ID: CustomStringConvertible {

  @FocusState private var isFocused: Bool
  @Binding private var element: Element
  @Binding private var isTargeted: Bool

  private let cornerRadius: Double
  private let focusPublisher: FocusPublisher<Element>
  private let selectionManager: SelectionManager<Element>
  private let style: FocusBackgroundViewStyle

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
        FocusOverlayView(isFocused: Binding<Bool>(get: { isFocused }, set: { isFocused = $0 }), 
                         isTargeted: $isTargeted,
                         cornerRadius: cornerRadius,
                         manager: selectionManager, style: style)
        .drawingGroup()
      )
      .background(
        FocusBackgroundView(isFocused: Binding<Bool>(get: { isFocused }, set: { isFocused = $0 }),
                            isTargeted: $isTargeted,
                            manager: selectionManager,
                            element: element,
                            cornerRadius: cornerRadius,
                            style: style)
        .drawingGroup()
      )
      .compositingGroup()
      .focused($isFocused)
  }
}

private struct FocusOverlayView<Element>: View where Element: Hashable, Element: Identifiable {
  @Binding private var isFocused: Bool
  @Binding private var isTargeted: Bool
  private let cornerRadius: Double
  private let manager: SelectionManager<Element>
  private let style: FocusBackgroundViewStyle

  init(isFocused: Binding<Bool>, isTargeted: Binding<Bool>, cornerRadius: Double,
       manager: SelectionManager<Element>, style: FocusBackgroundViewStyle) {
    _isFocused = isFocused
    _isTargeted = isTargeted
    self.cornerRadius = cornerRadius
    self.manager = manager
    self.style = style
  }

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
  @Binding private var isFocused: Bool
  @Binding private var isTargeted: Bool
  private let manager: SelectionManager<Element>
  private let element: Element
  private let cornerRadius: Double
  private let style: FocusBackgroundViewStyle

  init(isFocused: Binding<Bool>, isTargeted: Binding<Bool>,
       manager: SelectionManager<Element>, element: Element,
       cornerRadius: Double, style: FocusBackgroundViewStyle) {
    _isFocused = isFocused
    _isTargeted = isTargeted
    self.manager = manager
    self.element = element
    self.cornerRadius = cornerRadius
    self.style = style
  }

  var body: some View {
    manager.selectedColor
      .cornerRadius(cornerRadius)
      .opacity(focusOpacity())
      .id(element.id)
  }

  @MainActor
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

