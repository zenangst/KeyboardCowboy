import Cocoa

public protocol AppleScriptControlling {
  func run(_ source: ScriptCommand.Source) throws -> String
}

enum AppleScriptControllingError: Error {
  case failedToCreateInlineAppleScript
  case failedToLoadAppleScriptAtUrl(URL, NSDictionary?)
  case failedToRunAppleScript(String?)
}

class AppleScriptController: AppleScriptControlling {
  func run(_ source: ScriptCommand.Source) throws -> String {
    let appleScript: NSAppleScript
    switch source {
    case .inline(let source):
      guard let script = NSAppleScript(source: source) else {
        throw AppleScriptControllingError.failedToCreateInlineAppleScript
      }
      appleScript = script
    case .path(let path):
      var filePath = path
      filePath = (filePath as NSString).expandingTildeInPath
      filePath = filePath.replacingOccurrences(of: "", with: "\\ ")

      var dictionary: NSDictionary?
      let url = URL(fileURLWithPath: filePath)
      guard let script = NSAppleScript(contentsOf: url, error: &dictionary) else {
        throw AppleScriptControllingError.failedToLoadAppleScriptAtUrl(url, dictionary)
      }
      appleScript = script
    }

    try run(appleScript)

    return "true"
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
