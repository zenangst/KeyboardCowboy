import Commands
import CoreGraphics
import Foundation
import UserSpace

extension Operation {
  @MainActor
  struct ActivateLastApplication {
    struct PreviousApplication {
      let bundleIdentifier: String
      let bundleURL: URL?
    }

    let previousApplication: @MainActor () -> (PreviousApplication?, UserSpace.Snapshot)
    let openApplication: @MainActor (Command.Application, CGEventType?, UserSpace.Snapshot) async throws -> Void

    func callAsFunction() async throws -> SystemCommand.Completion {
      let (previous, snapshot) = previousApplication()
      try Task.checkCancellation()
      guard let previous else { return .noPreviousApplication }
      guard let url = previous.bundleURL else {
        throw SystemCommand.ExecutionError.missingPreviousApplicationBundleURL(previous.bundleIdentifier)
      }

      let bundle = Bundle(url: url)
      let name = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? url.deletingPathExtension().lastPathComponent
      let command = Command.Application(application: .init(
        bundleIdentifier: previous.bundleIdentifier, bundleName: name, path: url.path,
      ))
      try await openApplication(command, nil, snapshot)
      return .applicationOpenCompleted
    }
  }
}
