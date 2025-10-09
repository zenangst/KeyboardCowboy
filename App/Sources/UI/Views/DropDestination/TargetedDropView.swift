import SwiftUI

extension View {
  func dropDestination<T: Transferable & Equatable>(_ type: T.Type,
                                                    alignment: TargetedAlignment = .vertical,
                                                    color: Color, kind: TargetedKind = .reorder,
                                                    onDrop: @escaping ([T], CGPoint) -> Bool) -> some View
  {
    overlay {
      TargetedDropView(
        type,
        alignment: alignment,
        color: color,
        kind: kind,
        onDrop: onDrop,
      )
    }
  }
}

enum TargetedAlignment: Equatable {
  case vertical
  case horizontal
}

enum TargetedKind: Equatable {
  case reorder
  case drop
}

private struct TargetedDropView<T: Transferable & Equatable>: View, Equatable, Sendable {
  nonisolated static func == (lhs: TargetedDropView<T>, rhs: TargetedDropView<T>) -> Bool {
    lhs.kind == rhs.kind &&
      lhs.alignment == rhs.alignment &&
      lhs.type == rhs.type &&
      lhs.color == rhs.color
  }

  private let kind: TargetedKind
  private let alignment: TargetedAlignment
  private let type: T.Type
  private let color: Color
  private let onDrop: ([T], CGPoint) -> Bool

  init(_ type: T.Type,
       alignment: TargetedAlignment,
       color: Color,
       kind: TargetedKind,
       onDrop: @escaping ([T], CGPoint) -> Bool)
  {
    self.kind = kind
    self.type = type
    self.alignment = alignment
    self.color = color
    self.onDrop = onDrop
  }

  var body: some View {
    if LocalEventMonitor.shared.mouseDown {
      containerView(alignment,
                    content: {
                      switch kind {
                      case .reorder:
                        InternalTargetedDrop(type: type, targetAlignment: alignment,
                                             alignment: alignment == .vertical ? .top : .leading,
                                             color: color, onDrop: onDrop)
                        InternalTargetedDrop(type: type, targetAlignment: alignment,
                                             alignment: alignment == .vertical ? .bottom : .trailing,
                                             color: color, onDrop: onDrop)
                      case .drop:
                        Rectangle()
                          .fill(color.opacity(0.3))
                      }
                    })
    }
  }

  @ViewBuilder
  private func containerView(_ alignment: TargetedAlignment, @ViewBuilder content: () -> some View) -> some View {
    switch alignment {
    case .horizontal: HStack(spacing: 0, content: content)
    case .vertical: VStack(spacing: 0, content: content)
    }
  }
}

private struct InternalTargetedDrop<T: Transferable>: View {
  @State private var isTargeted: Bool = false
  private let type: T.Type
  private let targetAlignment: TargetedAlignment
  private let alignment: Alignment
  private let color: Color
  private let onDrop: ([T], CGPoint) -> Bool

  init(type: T.Type,
       targetAlignment: TargetedAlignment,
       alignment: Alignment,
       color: Color,
       onDrop: @escaping ([T], CGPoint) -> Bool)
  {
    self.type = type
    self.targetAlignment = targetAlignment
    self.alignment = alignment
    self.color = color
    self.onDrop = onDrop
  }

  var body: some View {
    Color
      .clear
      .overlay(alignment: alignment, content: {
        color
          .frame(
            maxWidth: targetAlignment == .vertical ? .infinity : 2,
            maxHeight: targetAlignment == .vertical ? 2 : .infinity,
          )
          .opacity(isTargeted ? 1 : 0)
      })
      .dropDestination(for: type, action: onDrop, isTargeted: {
        guard isTargeted != $0 else { return }

        isTargeted = $0
      })
  }
}
