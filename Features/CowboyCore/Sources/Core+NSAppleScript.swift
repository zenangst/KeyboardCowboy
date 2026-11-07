import Cocoa

public extension Core {
  final class NSAppleScript: Sendable {
    public enum Error: Swift.Error {
      case unableToCreateAppleScript(source: String)
      case unableToResolveAppleScript(path: String)
      case unableToCompile
      case unableToCompileWithError(Swift.Error)
      case unableToExecute(Swift.Error)
    }

    let mode: Mode

    enum Mode: @unchecked Sendable {
      case production(Cocoa.NSAppleScript)
      #if DEBUG
      case testing
      #endif
    }

    public init(_ env: Environment, source: String) throws {
      switch env {
      case .production:
        guard let appleScript = Cocoa.NSAppleScript(source: source) else {
          throw Error.unableToCreateAppleScript(source: source)
        }

        self.mode = .production(appleScript)
      #if DEBUG
      case .testing:
        self.mode = .testing
      #endif
      }
    }

    public init(
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
      #if DEBUG
      case .testing:
        self.mode = .testing
      #endif
      }
    }

    public func compileAndReturnError(_ errorInfo: AutoreleasingUnsafeMutablePointer<NSDictionary?>?) throws {
      var compilationError: NSDictionary?
      let succeeded: Bool
      switch mode {
      case .production(let appleScript):
        succeeded = appleScript.compileAndReturnError(&compilationError)
      #if DEBUG
      case .testing:
        succeeded = Testing.mock.compileAndReturnError
        if !succeeded, let error = Testing.mock.compileError() {
          compilationError = [
            Cocoa.NSAppleScript.errorNumber: error.code,
            Cocoa.NSAppleScript.errorMessage: error.localizedFailureReason ?? error.localizedDescription,
            Cocoa.NSAppleScript.errorBriefMessage: error.localizedDescription,
          ] as NSDictionary
        }
      #endif
      }
      errorInfo?.pointee = compilationError
      if !succeeded {
        if let compilationError {
          throw Error.unableToCompileWithError(try createError(from: compilationError))
        }
        throw Error.unableToCompile
      }
    }

    public func executeAndReturnError(_ errorInfo: AutoreleasingUnsafeMutablePointer<NSDictionary?>?)
      throws -> Core.NSAppleEventDescriptor {
      let descriptor: Core.NSAppleEventDescriptor
      switch mode {
      case .production(let appleScript):
        descriptor = NSAppleEventDescriptor(.production(appleScript.executeAndReturnError(errorInfo)))
      #if DEBUG
      case .testing:
        if let error = Testing.mock.execute() {
          errorInfo?.pointee = [
            Cocoa.NSAppleScript.errorNumber: error.code,
            Cocoa.NSAppleScript.errorMessage: error.localizedFailureReason ?? error.localizedDescription,
            Cocoa.NSAppleScript.errorBriefMessage: error.localizedDescription,
          ] as NSDictionary
        }
        descriptor = NSAppleEventDescriptor(.testing)
      #endif
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
