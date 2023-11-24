import SwiftUI

extension View {
  func dropDestination<T: Transferable>(_ type: T.Type, color: Color, onDrop: @escaping ([T], CGPoint) -> Bool) -> some View {
    self
      .modifier(TargetedDrop(type, color: color, onDrop: onDrop))
  }
}

struct TargetedDrop<T: Transferable>: ViewModifier {
  private let type: T.Type
  private let color: Color
  private let onDrop: ([T], CGPoint) -> Bool

  init(_ type: T.Type, color: Color, onDrop: @escaping ([T], CGPoint) -> Bool) {
    self.type = type
    self.color = color
    self.onDrop = onDrop
  }

  func body(content: Content) -> some View {
    content
      .overlay(TargetedDropView(type, color: color, onDrop: onDrop))
  }
}

private struct TargetedDropView<T: Transferable>: View {
  private let type: T.Type
  private let color: Color
  private let onDrop: ([T], CGPoint) -> Bool

  init(_ type: T.Type, color: Color, onDrop: @escaping ([T], CGPoint) -> Bool) {
    self.type = type
    self.color = color
    self.onDrop = onDrop
  }

  var body: some View {
    VStack(spacing: 0) {
      InternalTargetedDrop(type: type, alignment: .top, color: color, onDrop: onDrop)
      InternalTargetedDrop(type: type, alignment: .bottom, color: color, onDrop: onDrop)
    }
  }
}

private struct InternalTargetedDrop<T: Transferable>: View {
  @State var isTargeted: Bool = false
  let type: T.Type
  let alignment: Alignment
  let color: Color
  let onDrop: ([T], CGPoint) -> Bool

  var body: some View {
    Color
      .clear
      .overlay(alignment: alignment, content: {
        Rectangle()
          .fill(color)
          .frame(height: 2)
          .opacity(isTargeted ? 1 : 0)
      })
      .dropDestination(for: type, action: onDrop, isTargeted: {
        isTargeted = $0
      })
  }
}
