import Combine
import Cocoa

final class AppleScriptPlugin {
  enum AppleScriptPluginError: Error {
    case failedToCreateInlineScript
    case failedToCreateScriptAtURL(URL)
    case compileFailed(Error)
    case executionFailed(Error)
  }

  private let bundleIdentifier = Bundle.main.bundleIdentifier!
  private var cache = [String: NSAppleScript]()
  private var subscription: AnyCancellable?

  init(workspace: NSWorkspace) {
    subscription = workspace.publisher(for: \.frontmostApplication)
      .compactMap { $0 }
      .filter { $0.bundleIdentifier == self.bundleIdentifier }
      .sink { [weak self] _ in
        self?.cache = [:]
      }
  }

  func executeScript(at path: String, withId id: String) throws -> String? {
    if let cachedAppleScript = cache[id] {
      return cachedAppleScript.executeAndReturnError(nil).stringValue
    }

    let filePath = path.sanitizedPath
    let url = URL(fileURLWithPath: filePath)
    var errorDictionary: NSDictionary?

    guard let appleScript = NSAppleScript(contentsOf: url, error: &errorDictionary) else {
      throw AppleScriptPluginError.failedToCreateScriptAtURL(url)
    }

    try Task.checkCancellation()

    let descriptor = try execute(appleScript)

    cache[id] = appleScript

    return descriptor.stringValue
  }

  func execute(_ source: String, withId id: String) throws -> String? {
    if let cachedAppleScript = cache[id] {
      try Task.checkCancellation()
      return cachedAppleScript.executeAndReturnError(nil).stringValue
    }

    guard let appleScript = NSAppleScript(source: source) else {
      throw AppleScriptPluginError.failedToCreateInlineScript
    }

    try Task.checkCancellation()

    let descriptor = try execute(appleScript)

    cache[id] = appleScript

    return descriptor.stringValue
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
