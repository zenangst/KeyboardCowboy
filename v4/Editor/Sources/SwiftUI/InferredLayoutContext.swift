import SwiftUI

struct InferredLayoutContext: Equatable {
  let spacing: KeyPath<SpacingSpec, Double>?
  let inset: CGFloat

  static var empty: InferredLayoutContext { InferredLayoutContext(spacing: nil, inset: 0) }
}
