import SwiftUI

extension View {
  func dropDestination<T: Transferable>(_ type: T.Type,
                                        alignment: TargetedAlignment = .vertical,
                                        color: Color,
                                        kind: Binding<TargetedKind> = .constant(.reorder),
                                        onDrop: @escaping ([T], CGPoint ) -> Bool) -> some View {
    self.modifier(
      TargetedDrop(
        type,
        alignment: alignment,
        color: color,
        kind: kind,
        onDrop: onDrop
      )
    )
  }
}

struct TargetedDrop<T: Transferable>: ViewModifier {
  private let alignment: TargetedAlignment
  private let type: T.Type
  private let color: Color
  @Binding private var kind: TargetedKind
  private let onDrop: ([T], CGPoint) -> Bool

  init(_ type: T.Type,
       alignment: TargetedAlignment,
       color: Color,
       kind: Binding<TargetedKind>,
       onDrop: @escaping ([T], CGPoint) -> Bool) {
    _kind = kind
    self.type = type
    self.alignment = alignment
    self.color = color
    self.onDrop = onDrop
  }

  func body(content: Content) -> some View {
    content
      .overlay(
        TargetedDropView(
          type,
          alignment: alignment,
          color: color,
          kind: $kind,
          onDrop: onDrop
        )
      )
  }
}

enum TargetedAlignment {
  case vertical
  case horizontal
}

enum TargetedKind {
  case reorder
  case drop
}

private struct TargetedDropView<T: Transferable>: View {
  private let alignment: TargetedAlignment
  private let type: T.Type
  @Binding private var kind: TargetedKind
  private let color: Color
  private let onDrop: ([T], CGPoint) -> Bool

  init(_ type: T.Type,
       alignment: TargetedAlignment,
       color: Color,
       kind: Binding<TargetedKind>,
       onDrop: @escaping ([T], CGPoint) -> Bool
  ) {
    _kind = kind
    self.type = type
    self.alignment = alignment
    self.color = color
    self.onDrop = onDrop
  }

  var body: some View {
    containerView(alignment,
                  content: {
      switch kind {
      case .reorder:
        InternalTargetedDrop(
          type: type,
          targetAlignment: alignment,
          alignment: alignment == .vertical ? .top : .leading,
          color: color,
          onDrop: onDrop
        )
        InternalTargetedDrop(
          type: type,
          targetAlignment: alignment,
          alignment: alignment == .vertical ? .bottom : .trailing,
          color: color,
          onDrop: onDrop
        )
      case .drop:
        Rectangle()
          .fill(color.opacity(0.3))
      }
    })
  }

  @ViewBuilder
  private func containerView<Content: View>(_ alignment: TargetedAlignment, @ViewBuilder content: () -> Content) -> some View {
    switch alignment {
    case .horizontal: HStack(spacing: 0, content: content)
    case .vertical:   VStack(spacing: 0, content: content)
    }
  }
}

private struct InternalTargetedDrop<T: Transferable>: View {
  @State var isTargeted: Bool = false
  let type: T.Type
  let targetAlignment: TargetedAlignment
  let alignment: Alignment
  let color: Color
  let onDrop: ([T], CGPoint) -> Bool

  var body: some View {
    Color
      .clear
      .overlay(alignment: alignment, content: {
        Rectangle()
          .fill(color)
          .frame(
            width: targetAlignment == .vertical ? nil : 2,
            height: targetAlignment == .vertical ? 2 : nil
          )
          .opacity(isTargeted ? 1 : 0)
      })
      .dropDestination(for: type, action: onDrop, isTargeted: {
        isTargeted = $0
      })
  }
}
