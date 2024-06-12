import SwiftUI

struct FramePreferenceKey: PreferenceKey, Sendable {
  typealias Value = CGRect
  nonisolated(unsafe) static var defaultValue = CGRect.zero

  static func reduce(value: inout Value, nextValue: () -> Value) { }
}
