import Cocoa
import Combine

public protocol AppleScriptControlling: CommandPublishing {
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
  func run(_ source: ScriptCommand.Source)
}

enum AppleScriptControllingError: Error {
  case failedToCreateInlineAppleScript
  case failedToLoadAppleScriptAtUrl(URL, NSDictionary?)
  case failedToRunAppleScript(String?)
}

class AppleScriptController: AppleScriptControlling {
  internal let subject = PassthroughSubject<Command, Error>()

  func run(_ source: ScriptCommand.Source) {
    let appleScript: NSAppleScript
    switch source {
    case .inline(let source):
      guard let script = NSAppleScript(source: source) else {
        subject.send(completion: .failure(AppleScriptControllingError.failedToCreateInlineAppleScript))
        return
      }
      appleScript = script
    case .path(let path):
      let filePath = path.sanitizedPath
      var dictionary: NSDictionary?
      let url = URL(fileURLWithPath: filePath)
      guard let script = NSAppleScript(contentsOf: url, error: &dictionary) else {
        subject.send(completion: .failure(AppleScriptControllingError.failedToLoadAppleScriptAtUrl(url, dictionary)))
        return
      }
      appleScript = script
    }

    run(appleScript)
  }

  private func run(_ appleScript: NSAppleScript) {
    var dictionary: NSDictionary?
    appleScript.executeAndReturnError(&dictionary)
    let errorNumber = dictionary?["NSAppleScriptErrorNumber"] as? Int ?? -999
    // TODO: Improve error handling, this is based on the early prototype of the
    //       application. We should add a dictionary of known errors and properly
    //       map them into something user presentable.
    if [-1743, -1719].contains(errorNumber) {
      let message = dictionary?["NSAppleScriptErrorMessage"] as? String
      subject.send(completion: .failure(AppleScriptControllingError.failedToRunAppleScript(message ?? "Unknown error")))
    }

    subject.send(completion: .finished)
  }
}
