import Cocoa
import CowboyCore

extension Core {
  final class NSAppleScript: Sendable {
    enum Error: Swift.Error {
      case unableToCreateAppleScript(source: String)
      case unableToResolveAppleScript(path: String)
      case unableToCompile
      case unableToExecute(Swift.Error)
    }

    let mode: Mode

    public enum Testing {
      @TaskLocal public static var mock: Mock = Mock()
    }

    public struct Mock: Sendable {
      var compileAndReturnError: Bool = false
    }

    enum Mode: @unchecked Sendable {
      case production(Cocoa.NSAppleScript)
      case testing
    }

    init(_ env: Environment, source: String) throws {
      switch env {
      case .production:
        guard let appleScript = Cocoa.NSAppleScript(source: source) else {
          throw Error.unableToCreateAppleScript(source: source)
        }

        self.mode = .production(appleScript)
      case .testing:
        self.mode = .testing
      }
    }

    init(
      _ env: Environment,
      contentsOf url: URL,
      error errorInfo: AutoreleasingUnsafeMutablePointer<NSDictionary?>?,
    ) throws {
      switch env {
      case .production:
        guard let appleScript = Cocoa.NSAppleScript(contentsOf: url, error: errorInfo) else {
          throw Error.unableToResolveAppleScript(path: url.absoluteString)
        }

        self.mode = .production(appleScript)
      case .testing:
        self.mode = .testing
      }
    }

    func compileAndReturnError(_ errorInfo: AutoreleasingUnsafeMutablePointer<NSDictionary?>?) throws {
      switch mode {
      case .production(let appleScript):
        if !appleScript.compileAndReturnError(errorInfo) {
          throw Error.unableToCompile
        }
      case .testing:
        if !Testing.mock.compileAndReturnError {
          throw Error.unableToCompile
        }
      }
    }

    func executeAndReturnError(_ errorInfo: AutoreleasingUnsafeMutablePointer<NSDictionary?>?)
      throws -> Core.NSAppleEventDescriptor {
      let descriptor = switch mode {
      case .production(let appleScript):
        NSAppleEventDescriptor(.production(appleScript.executeAndReturnError(errorInfo)))
      case .testing:
        NSAppleEventDescriptor(.testing)
      }

      if let errorInfo = errorInfo?.pointee {
        throw Error.unableToExecute(try createError(from: errorInfo))
      }

      return descriptor
    }

    private func createError(from dictionary: NSDictionary) throws -> NSError {
      let code = dictionary[Cocoa.NSAppleScript.errorNumber] as? Int ?? 0

      let errorMessage = dictionary[Cocoa.NSAppleScript.errorMessage] as? String ?? "Missing error message"
      let descriptionMessage = dictionary[Cocoa.NSAppleScript.errorBriefMessage] ?? "Missing description"
      let errorDomain = "com.zenangst.KeyboardCowboy.AppleScriptPlugin"
      let error = NSError(domain: errorDomain, code: code, userInfo: [
        NSLocalizedFailureReasonErrorKey: errorMessage,
        NSLocalizedDescriptionKey: descriptionMessage,
      ])
      return error
    }
  }
}
