import Combine
import Foundation
import ModelKit

public protocol BuiltInCommandControlling {
  func run(_ command: BuiltInCommand) -> CommandPublisher
}

public class BuiltInCommandControllerMock: BuiltInCommandControlling {
  public func run(_ command: BuiltInCommand) -> CommandPublisher {
    Future { promise in
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
}
