import SwiftUI

struct InferredLayoutContextPreferenceKey: PreferenceKey {
  static var defaultValue: InferredLayoutContext { .empty }

  static func reduce(value: inout InferredLayoutContext, nextValue: () -> InferredLayoutContext) {
    let next = nextValue()

    if next != .empty {
      value = next
    }
  }
}
