import SwiftUI

struct InferredLayoutContext: Equatable {
  let spacing: KeyPath<SpacingSpec, Double>?
  let inset: CGFloat

  static var empty: InferredLayoutContext { InferredLayoutContext(spacing: nil, inset: 0) }
}

struct InferredLayoutContextPreferenceKey: PreferenceKey {
  static var defaultValue: InferredLayoutContext { .empty }

  static func reduce(value: inout InferredLayoutContext, nextValue: () -> InferredLayoutContext) {
    let next = nextValue()

    if next != .empty {
      value = next
    }
  }
}
