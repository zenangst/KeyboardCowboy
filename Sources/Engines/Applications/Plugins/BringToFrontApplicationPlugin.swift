import Cocoa

/// Bring the current applications windows to front using Apple Scripting
/// This is only here because sending `.activateAllWindows` to `NSRunningApplication.activate()`
/// currently does not work as expected.
final class BringToFrontApplicationPlugin {
  enum BringToFrontApplicationPluginError: Error {
    case failedToCreate
    case failedToCompile
    case failedToRun
  }

  private var cache: NSAppleScript?

  func execute(_ command: ApplicationCommand) async throws {
    guard let script: NSAppleScript = cache ?? createAppleScript(command) else {
      throw BringToFrontApplicationPluginError.failedToCreate
    }

    var dictionary: NSDictionary?

    if !script.isCompiled && self.cache == nil {
      script.compileAndReturnError(&dictionary)
      if dictionary != nil {
        throw BringToFrontApplicationPluginError.failedToCompile
      }

      self.cache = script
    }

    script.executeAndReturnError(&dictionary)

    if let dictionary = dictionary,
       let error = createError(from: dictionary) {
      throw error
    }
  }

  private func createAppleScript(_ command: ApplicationCommand) -> NSAppleScript? {
    let source = """
      tell application "System Events"
        set frontmostProcess to first process where it is frontmost
        click (menu item "Bring All to Front" of menu "Window" of menu bar 1 of frontmostProcess)
      end tell
      """
    return NSAppleScript(source: source)
  }

  private func createError(from dictionary: NSDictionary) -> Error? {
    let code = dictionary[NSAppleScript.errorNumber] as? Int ?? 0
    let errorMessage = dictionary[NSAppleScript.errorMessage] as? String ?? "Missing error message"
    let descriptionMessage = dictionary[NSAppleScript.errorBriefMessage] ?? "Missing description"
    let errorDomain = "com.zenangst.KeyboardCowboy.AppleScriptController"
    let error = NSError(domain: errorDomain, code: code, userInfo: [
      NSLocalizedFailureReasonErrorKey: errorMessage,
      NSLocalizedDescriptionKey: descriptionMessage
    ])
    return error
  }
}
