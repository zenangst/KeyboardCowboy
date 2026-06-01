import Cocoa
import CowboyCore
import System

extension AppleScript {
  final class Executor {
    let cache: Cache
    let env: Core.Environment

    init(_ env: Core.Environment) {
      self.cache = Cache()
      self.env = env
    }

    func execute(_ filePath: FilePath, key: String) throws -> (appleScript: Core.NSAppleScript, output: String?) {
      if let appleScript = cache.get(for: key) {
        return (appleScript, try appleScript.executeAndReturnError(nil).stringValue)
      }

      var errorDictionary: NSDictionary?

      let appleScript = try Core.NSAppleScript(env, contentsOf: URL(filePath: filePath.string), error: &errorDictionary)
      try appleScript.compileAndReturnError(&errorDictionary)
      let descriptor = try appleScript.executeAndReturnError(&errorDictionary)

      cache.set(appleScript, for: key)

      return (appleScript, descriptor.stringValue)
    }

    func execute(_ source: String, key: String) throws -> (appleScript: Core.NSAppleScript, output: String?) {
      if let appleScript = cache.get(for: key) {
        return (appleScript, try appleScript.executeAndReturnError(nil).stringValue)
      }

      var errorDictionary: NSDictionary?

      let appleScript = try Core.NSAppleScript(env, source: source)
      try appleScript.compileAndReturnError(&errorDictionary)
      let descriptor = try appleScript.executeAndReturnError(&errorDictionary)

      cache.set(appleScript, for: key)

      return (appleScript, descriptor.stringValue)
    }
  }
}
