import Foundation
import Cocoa

final class Benchmark {
  var isEnabled: Bool = false

  private var storage = [String: Double]()

  nonisolated(unsafe) static let shared: Benchmark = .init()

  private init() {}

  nonisolated func start(_ identifier: @autoclosure @Sendable () -> String, forceEnable: Bool = false) {
    guard (isEnabled || forceEnable) else { return }
    if storage[identifier()] != nil {
      debugPrint("⏱ Benchmark: duplicate start")
    }
    storage[identifier()] = CACurrentMediaTime()
  }

  @discardableResult
  func stop(_ identifier: @autoclosure @Sendable () -> String, forceEnable: Bool = false) -> String {
    guard (isEnabled || forceEnable), let startTime = storage[identifier()] else {
      return "Unknown identifier: \(identifier())"
    }
    Swift.print("⏱️ Benchmark(\(identifier())) = \(CACurrentMediaTime() - startTime) ")
    storage[identifier()] = nil
    return "⏱ Benchmark(\(identifier())) = \(CACurrentMediaTime() - startTime) "
  }
}
