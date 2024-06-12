import Combine
import Cocoa

enum AppleScriptPluginError: Error {
  case failedToCreateInlineScript
  case failedToCreateScriptAtURL(URL)
  case compileFailed(Error)
  case executionFailed(Error)
}

extension NSAppleScript: @unchecked @retroactive Sendable {}

actor AppleScriptCache: @unchecked Sendable {
  private var storage = [String: NSAppleScript]()

  func clear() {
    storage = [:]
  }

  func set(_ appleScript: NSAppleScript, for key: String) {
    storage[key] = appleScript
  }

  func get(_ key: String) -> NSAppleScript? {
    storage[key]
  }
}

final class AppleScriptPlugin: @unchecked Sendable {
  private let bundleIdentifier = Bundle.main.bundleIdentifier!
  private let cache = AppleScriptCache()
  private var frontmostApplicationSubscription: AnyCancellable?

  init(workspace: NSWorkspace) {
    frontmostApplicationSubscription = workspace.publisher(for: \.frontmostApplication)
      .compactMap { $0 }
      .filter { $0.bundleIdentifier == self.bundleIdentifier }
      .sink { [cache] _ in
        Task { await cache.clear() }
      }
  }

  func executeScript(at path: String, withId key: String, checkCancellation: Bool) async throws -> String? {
    if let cachedAppleScript = await cache.get(key) {
      return cachedAppleScript.executeAndReturnError(nil).stringValue
    }

    let filePath = path.sanitizedPath
    let url = URL(fileURLWithPath: filePath)
    var errorDictionary: NSDictionary?

    guard let appleScript = NSAppleScript(contentsOf: url, error: &errorDictionary) else {
      throw AppleScriptPluginError.failedToCreateScriptAtURL(url)
    }

    if checkCancellation { try Task.checkCancellation() }
    let descriptor = try self.execute(appleScript)
    await cache.set(appleScript, for: key)
    return descriptor.stringValue
  }

  func execute(_ source: String, withId id: String, checkCancellation: Bool) async throws -> String? {
    if let cachedAppleScript = await cache.get(id) {
      do {
        try Task.checkCancellation()
      } catch {
        throw error
      }
      return cachedAppleScript.executeAndReturnError(nil).stringValue
    }

    guard let appleScript = NSAppleScript(source: source) else {
      throw AppleScriptPluginError.failedToCreateInlineScript
    }

    do {
      if checkCancellation { try Task.checkCancellation() }
      let descriptor = try self.execute(appleScript)
      await cache.set(appleScript, for: id)
      return descriptor.stringValue
    } catch {
      throw error
    }
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
