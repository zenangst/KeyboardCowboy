import Cocoa
import CowboyCore
import System

extension AppleScript {
  final class Executor { let cache: Cache
    let env: Core.Environment

    init(_ env: Core.Environment) {
      self.cache = Cache(env)
      self.env = env
    }

    func execute(_ filePath: FilePath, key: String) throws -> String? {
      if let cached = cache.get(for: key) {
        return try cached.executeAndReturnError(nil).stringValue
      }

      var errorDictionary: NSDictionary?

      let appleScript = try Core.NSAppleScript(env, contentsOf: URL(filePath: filePath.string), error: &errorDictionary)
      try appleScript.compileAndReturnError(&errorDictionary)
      let descriptor = try appleScript.executeAndReturnError(&errorDictionary)

      cache.set(appleScript, for: key)

      return descriptor.stringValue
    }

    func execute(_ source: String, key: String) throws -> String? {
      if let cached = cache.get(for: key) {
        return try cached.executeAndReturnError(nil).stringValue
      }

      var errorDictionary: NSDictionary?

      let appleScript = try Core.NSAppleScript(env, source: source)
      let descriptor = try appleScript.executeAndReturnError(&errorDictionary)

      cache.set(appleScript, for: key)

      return descriptor.stringValue
    }
  }
}
