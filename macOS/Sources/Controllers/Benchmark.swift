import Foundation
import Cocoa

final class Benchmark {
  static var storage = [String: Double]()
  static var isEnabled: Bool = false

  static func start(_ identifier: String) {
    guard isEnabled else { return }
    if storage[identifier] != nil {
      debugPrint("⏱ Benchmark: duplicate start")
    }
    storage[identifier] = CACurrentMediaTime()
  }

  @discardableResult
  static func finish(_ identifier: String) -> String {
    guard isEnabled, let startTime = storage[identifier] else {
      return "Unknown identifier: \(identifier)"
    }
    Swift.print("⏱️ Benchmark(\(identifier)) = \(CACurrentMediaTime() - startTime) ")
    storage[identifier] = nil
    return "⏱ Benchmark(\(identifier)) = \(CACurrentMediaTime() - startTime) "
  }
}
