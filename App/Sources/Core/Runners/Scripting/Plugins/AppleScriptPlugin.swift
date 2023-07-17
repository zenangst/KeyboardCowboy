import Combine
import Cocoa

enum AppleScriptPluginError: Error {
  case failedToCreateInlineScript
  case failedToCreateScriptAtURL(URL)
  case compileFailed(Error)
  case executionFailed(Error)
}

final class AppleScriptPlugin {

  private let bundleIdentifier = Bundle.main.bundleIdentifier!
  private let queue = DispatchQueue(label: "ApplicationPlugin")

  private var cache = [String: NSAppleScript]()
  private var frontmostApplicationSubscription: AnyCancellable?


  init(workspace: NSWorkspace) {
    frontmostApplicationSubscription = workspace.publisher(for: \.frontmostApplication)
      .compactMap { $0 }
      .filter { $0.bundleIdentifier == self.bundleIdentifier }
      .receive(on: queue)
      .sink { [weak self] _ in
        guard let self else { return }
        self.cache = [:]
      }
  }

  func executeScript(at path: String, withId id: String) async throws -> String? {
    try await withCheckedThrowingContinuation { continuation in
      queue.async {
        if let cachedAppleScript = self.cache[id] {
          continuation.resume(with: .success(cachedAppleScript.executeAndReturnError(nil).stringValue))
          return
        }

        let filePath = path.sanitizedPath
        let url = URL(fileURLWithPath: filePath)
        var errorDictionary: NSDictionary?

        guard let appleScript = NSAppleScript(contentsOf: url, error: &errorDictionary) else {
          continuation.resume(throwing: AppleScriptPluginError.failedToCreateScriptAtURL(url))
          return
        }

        do {
          try Task.checkCancellation()
          let descriptor = try self.execute(appleScript)
          self.cache[id] = appleScript
          return continuation.resume(with: .success(descriptor.stringValue))
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  func execute(_ source: String, withId id: String) async throws -> String? {
    try await withCheckedThrowingContinuation { continuation in
      queue.async {
        if let cachedAppleScript = self.cache[id] {
          do {
            try Task.checkCancellation()
          } catch {
            continuation.resume(throwing: error)
            return
          }
          continuation.resume(with: .success(cachedAppleScript.executeAndReturnError(nil).stringValue))
          return
        }

        guard let appleScript = NSAppleScript(source: source) else {
          continuation.resume(throwing: AppleScriptPluginError.failedToCreateInlineScript)
          return
        }

        do {
          try Task.checkCancellation()
          let descriptor = try self.execute(appleScript)
          continuation.resume(with: .success(descriptor.stringValue))
          self.cache[id] = appleScript
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  // MARK: Private methods

  private func execute(_ appleScript: NSAppleScript) throws -> NSAppleEventDescriptor {
    var errorDictionary: NSDictionary?

    appleScript.compileAndReturnError(&errorDictionary)

    if let errorDictionary = errorDictionary {
      throw AppleScriptPluginError.compileFailed(createError(from: errorDictionary))
    }

    let descriptor = appleScript.executeAndReturnError(&errorDictionary)

    if let errorDictionary = errorDictionary {
      throw AppleScriptPluginError.executionFailed(createError(from: errorDictionary))
    }

    return descriptor
  }

  private func createError(from dictionary: NSDictionary) -> Error {
    let code = dictionary[NSAppleScript.errorNumber] as? Int ?? 0
    let errorMessage = dictionary[NSAppleScript.errorMessage] as? String ?? "Missing error message"
    let descriptionMessage = dictionary[NSAppleScript.errorBriefMessage] ?? "Missing description"
    let errorDomain = "com.zenangst.KeyboardCowboy.AppleScriptPlugin"
    let error = NSError(domain: errorDomain, code: code, userInfo: [
      NSLocalizedFailureReasonErrorKey: errorMessage,
      NSLocalizedDescriptionKey: descriptionMessage
    ])
    return error
  }
}
