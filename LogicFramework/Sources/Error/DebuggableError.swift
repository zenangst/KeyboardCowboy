import Foundation

public protocol DebuggableError {
  var underlyingError: Error { get }
}
