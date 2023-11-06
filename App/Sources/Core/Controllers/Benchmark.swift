import Foundation
import Cocoa

@MainActor
final class Benchmark {
  var isEnabled: Bool = false

  private var storage = [String: Double]()

  static let shared: Benchmark = .init()

  private init() {}

  func start(_ identifier: @autoclosure @Sendable () -> String) {
    guard isEnabled else { return }
    if storage[identifier()] != nil {
      debugPrint("⏱ Benchmark: duplicate start")
    }
    storage[identifier()] = CACurrentMediaTime()
  }

  @discardableResult
  func finish(_ identifier: @autoclosure @Sendable () -> String) -> String {
    guard isEnabled, let startTime = storage[identifier()] else {
      return "Unknown identifier: \(identifier())"
    }
    Swift.print("⏱️ Benchmark(\(identifier())) = \(CACurrentMediaTime() - startTime) ")
    storage[identifier()] = nil
    return "⏱ Benchmark(\(identifier())) = \(CACurrentMediaTime() - startTime) "
  }
}
