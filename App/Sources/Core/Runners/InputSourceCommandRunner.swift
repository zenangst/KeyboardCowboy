import Foundation
import InputSources

@MainActor
final class InputSourceCommandRunner {
  private let controller: InputSourceController

  init() {
    controller = InputSourceController()
  }

  func run(_ command: KeyboardCommand.InputSourceCommand) async throws {
    let currentInputSource = try controller.currentInputSource()

    if currentInputSource.id == command.inputSourceId {
      return
    }

    try Task.checkCancellation()

    let inputSource = try controller.findInput(command.inputSourceId, includeAllInstalled: false)
    try controller.select(inputSource)
  }
}
