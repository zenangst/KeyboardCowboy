import Cocoa
import Foundation

final class Benchmark {
  var isEnabled: Bool = false

  private var storage = [String: Double]()

  nonisolated(unsafe) static let shared: Benchmark = .init()

  private init() {}

  nonisolated func start(_ identifier: @autoclosure @Sendable () -> String,
                         value _: @autoclosure @Sendable () -> String = "", forceEnable: Bool = false) {
    guard isEnabled || forceEnable else { return }

    if storage[identifier()] != nil {
      debugPrint("⏱ Benchmark: duplicate start")
    }
    storage[identifier()] = CACurrentMediaTime()
  }

  @discardableResult
  func lap(_ identifier: @autoclosure @Sendable () -> String,
           value: @autoclosure @Sendable () -> String = "",
           forceEnable: Bool = false, function: StaticString = #function, line: Int = #line) -> String {
    guard isEnabled || forceEnable, let startTime = storage[identifier()] else {
      return "Unknown identifier: \(identifier())"
    }

    Swift.print("⏱️ (\(identifier())):\(function)\(line) (\(value()) = \(CACurrentMediaTime() - startTime) \n")
    return "⏱ Benchmark(\(identifier()))-(\(value())):\(function)\(line) = \(CACurrentMediaTime() - startTime) "
  }

  @discardableResult
  func stop(_ identifier: @autoclosure @Sendable () -> String,
            value: @autoclosure @Sendable () -> String = "",
            forceEnable: Bool = false) -> String {
    guard isEnabled || forceEnable, let startTime = storage[identifier()] else {
      return "Unknown identifier: \(identifier())"
    }

    Swift.print("⏱️ (\(identifier()))\(value()) = \(CACurrentMediaTime() - startTime)")
    Swift.print("-------------------------- \n")
    storage[identifier()] = nil
    return "⏱ Benchmark(\(identifier())) = \(CACurrentMediaTime() - startTime) "
  }
}
