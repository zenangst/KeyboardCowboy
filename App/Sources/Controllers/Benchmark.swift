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

  static func finish(_ identifier: String) {
    guard isEnabled else { return }
    guard let startTime = storage[identifier] else {
      return
    }
    debugPrint("⏱ Benchmark(\(identifier)) = \(CACurrentMediaTime() - startTime) ")
    storage[identifier] = nil
  }
}
