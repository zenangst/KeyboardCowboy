import Cocoa
import Combine

public protocol AppleScriptControlling {
  /// Run a AppleScript based on which `Source` is supplied.
  ///
  /// Source is a value-type that decided which type of AppleScript
  /// should be invoked. There are two types of script sources:
  ///
  /// `.inline` - A script that is embedded in the command
  /// `.path` - A script that is located on disk
  ///
  /// - Parameter source: A `Source` enum that decides how the
  ///                     AppleScript should be constructed
  /// - Returns: A publisher that wraps a result of the run operation.
  func run(_ source: ScriptCommand.Source) -> CommandPublisher
}

enum AppleScriptControllingError: Error {
  case failedToCreateInlineAppleScript
  case failedToLoadAppleScriptAtUrl(URL, NSDictionary?)
  case failedToRunAppleScript(String?)
}

class AppleScriptController: AppleScriptControlling {
  func run(_ source: ScriptCommand.Source) -> CommandPublisher {
    let appleScript: NSAppleScript

    switch source {
    case .inline(let source):
      guard let script = NSAppleScript(source: source) else {
        return Fail(error: AppleScriptControllingError.failedToCreateInlineAppleScript).eraseToAnyPublisher()
      }
      appleScript = script
    case .path(let path):
      let filePath = path.sanitizedPath
      var dictionary: NSDictionary?
      let url = URL(fileURLWithPath: filePath)
      guard let script = NSAppleScript(contentsOf: url, error: &dictionary) else {
        return Fail(error: AppleScriptControllingError.failedToLoadAppleScriptAtUrl(url, dictionary))
          .eraseToAnyPublisher()
      }
      appleScript = script
    }

    do {
      try run(appleScript)
      return Result.success(()).publisher.eraseToAnyPublisher()
    } catch {
      return Fail(error: error).eraseToAnyPublisher()
    }
  }

  private func run(_ appleScript: NSAppleScript) throws {
    var dictionary: NSDictionary?
    appleScript.executeAndReturnError(&dictionary)
    let errorNumber = dictionary?["NSAppleScriptErrorNumber"] as? Int ?? -999
    // TODO: Improve error handling, this is based on the early prototype of the
    //       application. We should add a dictionary of known errors and properly
    //       map them into something user presentable.
    if [-1743, -1719].contains(errorNumber) {
      let message = dictionary?["NSAppleScriptErrorMessage"] as? String
      throw AppleScriptControllingError.failedToRunAppleScript(message ?? "Unknown error")
    }
  }
}
