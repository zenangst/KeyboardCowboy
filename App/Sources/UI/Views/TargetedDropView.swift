import SwiftUI

public struct TargetedDropView<T: Transferable>: View {
  @Binding var isTargeted: Bool
  let type: T.Type
  let color: Color
  let onDrop: ([T], CGPoint) -> Bool

  public init(
    _ type: T.Type,
    isTargeted: Binding<Bool>,
    color: Color,
    onDrop: @escaping ([T], CGPoint) -> Bool
  ) {
    _isTargeted = isTargeted
    self.type = type
    self.color = color
    self.onDrop = onDrop
  }

  public var body: some View {
    VStack(spacing: 0) {
      InternalTargetDropView(type, isTargeted: $isTargeted, alignment: .top, color: color, onDrop: onDrop)
      InternalTargetDropView(type, isTargeted: $isTargeted, alignment: .bottom, color: color, onDrop: onDrop)
    }
  }
}

private struct InternalTargetDropView<T: Transferable>: View {
  @State var isHovered: Bool = false
  @Binding var isTargeted: Bool
  let alignment: Alignment
  let color: Color
  let type: T.Type
  let onDrop: ([T], CGPoint) -> Bool

  init(
    _ type: T.Type,
    isTargeted: Binding<Bool>,
    alignment: Alignment,
    color: Color,
    onDrop: @escaping ([T], CGPoint) -> Bool
  ) {
    self.type = type
    _isTargeted = isTargeted
    self.alignment = alignment
    self.color = color
    self.onDrop = onDrop
  }

  var body: some View {
    Color
      .clear
      .overlay(alignment: alignment, content: {
        RoundedRectangle(cornerRadius: 4)
          .fill(color)
          .frame(height: 2)
          .opacity(isHovered ? 1 : 0)
      })
      .opacity(isHovered ? 1.0 : 0)
      .dropDestination(for: T.self, action: onDrop, isTargeted: { newValue in
        isHovered = newValue
      })
  }
}
