import SwiftUI

extension Binding {
  @MainActor
  init(_ handler: @autoclosure @escaping @MainActor @Sendable () -> Value) where Value: Sendable {
    self.init(get: handler, set: { @Sendable @MainActor _ in })
  }

  @MainActor
  static func readonly(_ value: @MainActor @escaping @Sendable () -> Value) -> Binding<Value> where Value: Sendable {
    Binding(get: {
      value()
    }, set: { _ in })
  }
}
