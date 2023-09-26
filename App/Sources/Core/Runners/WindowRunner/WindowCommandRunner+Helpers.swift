import Foundation

extension CGRect {
  func aspectRatio(to rect: CGRect) -> CGSize {
    CGSize(width: width / rect.width, height: height / rect.height)
  }
}

extension CGFloat {
  static func formula(_ initialValue: CGFloat = 0, 
                      debug prefix: String? = nil,
                      @GenericBuilder<Math> _ builder: (Math.Type) -> [Math]) -> CGFloat {
    let instructions = builder(Math.self)
    var result: CGFloat = initialValue.rounded()

    var debugString = "\(initialValue)"

    for instruction in instructions {
      switch instruction {
      case .add(let fn):
        let value = fn().rounded()
        debugString += " + \(value)"
        result += value

      case .subtract(let fn):
        let value = fn().rounded()
        debugString += " - \(value)"
        result -= value
      }
    }

    debugString += " = \(result)"

    if let prefix { print("🧮 \(prefix) \(debugString)") }

    return result
  }
}

enum Math {
  case add(@autoclosure () -> CGFloat)
  case subtract(@autoclosure () -> CGFloat)
}

@resultBuilder
public struct GenericBuilder<T> {
  static public func buildBlock(_ components: T...) -> [T] {
    components
  }
}
