import Foundation

public extension AppleScriptRuntime.NSAppleScript {
  enum Error: Swift.Error {
    case unableToCreateAppleScript(source: String)
    case unableToResolveAppleScript(path: String)
    case unableToResolveAppleScriptWithError(path: String, underlyingError: NSError)
    case unableToCompile
    case unableToCompileWithError(Swift.Error)
    case unableToExecute(Swift.Error)
  }
}
