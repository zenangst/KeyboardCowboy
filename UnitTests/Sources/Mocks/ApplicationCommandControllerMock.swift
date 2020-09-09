import Foundation
import LogicFramework

class ApplicationCommandControllerMock: ApplicationCommandControlling {
  typealias Handler = () throws -> Void
  let handler: Handler

  init(_ handler: @escaping Handler = {}) {
    self.handler = handler
  }

  func run(_ command: ApplicationCommand) throws {
    try handler()
  }
}
