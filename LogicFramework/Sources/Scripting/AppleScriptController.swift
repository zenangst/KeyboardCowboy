import Cocoa
import Combine
import ModelKit

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

enum AppleScriptControllingError: Error, DebuggableError {
  case failedToCreateInlineAppleScript
  case failedToLoadAppleScriptAtUrl(URL, NSDictionary?)
  case failedToRunAppleScript(Error)

  var underlyingError: Error {
    switch self {
    case .failedToCreateInlineAppleScript:
      return NSError(domain: "com.zenangst.KeyboardCowboy",
                     code: -999, userInfo: [
                      NSLocalizedDescriptionKey: "Unable to create inline script"
                     ])
    case .failedToLoadAppleScriptAtUrl(let url, _):
      return NSError(domain: "com.zenangst.KeyboardCowboy",
                     code: -999, userInfo: [
                      NSLocalizedDescriptionKey: "Unable to load AppleScript at path: \(url.absoluteString)"
                     ])
    case .failedToRunAppleScript(let error):
      return error
    }
  }
}

final class AppleScriptController: AppleScriptControlling {
  let queue: DispatchQueue = .init(label: "com.zenangst.Keyboard-Cowboy.AppleScriptControllerQueue",
                                   qos: .userInitiated)
  var cache = [String: NSAppleScript]()

  func run(_ source: ScriptCommand.Source) -> CommandPublisher {
    Future { [weak self] promise in
      guard let self = self else { return }
      self.queue.async {
        let appleScript: NSAppleScript

        switch source {
        case .inline(let source):
          guard let script = NSAppleScript(source: source) else {
            promise(.failure(AppleScriptControllingError.failedToCreateInlineAppleScript))
            return
          }
          appleScript = script
        case .path(let path):
          let filePath = path.sanitizedPath
          if let cachedScript = self.cache[filePath] {
            appleScript = cachedScript
          } else {
            var dictionary: NSDictionary?
            let url = URL(fileURLWithPath: filePath)
            guard let script = NSAppleScript(contentsOf: url, error: &dictionary) else {
              promise(.failure(AppleScriptControllingError.failedToLoadAppleScriptAtUrl(url, dictionary)))
              return
            }
            appleScript = script
            self.cache[filePath] = appleScript
          }
        }

        if !appleScript.isCompiled {
          var compilerError: NSDictionary?
          appleScript.compileAndReturnError(&compilerError)
          if let compilerError = compilerError {
            let error = NSError(domain: "com.zenangst.KeyboardCowboy.AppleScriptController",
                                code: -999, userInfo: compilerError as? [String: Any])
            promise(.failure(error))
            return
          }
        }

        do {
          try self.run(appleScript)
          promise(.success(()))
        } catch let error {
          promise(.failure(error))
        }
      }
    }
    .eraseToAnyPublisher()
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

  private func run(_ appleScript: NSAppleScript) throws {
    var dictionary: NSDictionary?
    appleScript.executeAndReturnError(&dictionary)
    if let dictionary = dictionary,
       let error = createError(from: dictionary) {
      throw AppleScriptControllingError.failedToRunAppleScript(error)
    }
  }
}
