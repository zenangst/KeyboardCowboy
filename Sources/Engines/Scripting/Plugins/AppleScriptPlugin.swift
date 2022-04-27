import Foundation

final class AppleScriptPlugin {
  enum AppleScriptPluginError: Error {
    case failedToCreateInlineScript
    case failedToCreateScriptAtURL(URL)
    case compileFailed(Error)
    case executionFailed(Error)
  }

  private var cache = [String: NSAppleScript]()

  func executeScript(at path: String, withId id: String) throws {
    let filePath = path.sanitizedPath
    let url = URL(fileURLWithPath: filePath)

    if let cachedAppleScript = cache[id] {
      cachedAppleScript.executeAndReturnError(nil)
      return
    }

    var errorDictionary: NSDictionary?

    guard let appleScript = NSAppleScript(contentsOf: url, error: &errorDictionary) else {
      throw AppleScriptPluginError.failedToCreateScriptAtURL(url)
    }

    try execute(appleScript)

    cache[id] = appleScript
  }

  func execute(_ source: String, withId id: String) throws {
    if let cachedAppleScript = cache[id] {
      cachedAppleScript.executeAndReturnError(nil)
      return
    }

    guard let appleScript = NSAppleScript(source: source) else {
      throw AppleScriptPluginError.failedToCreateInlineScript
    }

    try execute(appleScript)

    cache[id] = appleScript
  }

  // MARK: Private methods

  private func execute(_ appleScript: NSAppleScript) throws {
    var errorDictionary: NSDictionary?

    appleScript.compileAndReturnError(&errorDictionary)

    if let errorDictionary = errorDictionary {
      throw AppleScriptPluginError.compileFailed(createError(from: errorDictionary))
    }

    appleScript.executeAndReturnError(&errorDictionary)

    if let errorDictionary = errorDictionary {
      throw AppleScriptPluginError.executionFailed(createError(from: errorDictionary))
    }
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
