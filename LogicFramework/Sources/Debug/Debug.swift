import Foundation

public final class Debug {
  public static var isEnabled: Bool = false

  public static func print(_ statement: @autoclosure () -> String,
                           filePath: StaticString = #file,
                           function: StaticString = #function,
                           line: UInt = #line) {
    guard isEnabled else { return }
    let file = ("\(filePath)" as NSString).lastPathComponent
    let output = "\(file):\(line) -> \(function): \(statement())"
    debugPrint(output)
  }
}
