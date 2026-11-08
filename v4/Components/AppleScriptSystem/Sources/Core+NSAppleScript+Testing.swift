#if DEBUG
import CowboyCore
import Foundation

extension Core.NSAppleScript {
  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    var compileAndReturnError: Bool
    var execute: @Sendable () -> NSError?
    var compileError: @Sendable () -> NSError?
    let createSource: @Sendable (String) -> Bool
    let createFile: @Sendable (URL) -> Bool
    let onCompile: @Sendable () -> Void
    let createFileError: @Sendable (URL) -> NSError?

    public init(
      compileAndReturnError: Bool = false,
      execute: @escaping @Sendable () -> NSError? = { nil },
      compileError: @escaping @Sendable () -> NSError? = { nil },
      createSource: @escaping @Sendable (String) -> Bool = { _ in true },
      createFile: @escaping @Sendable (URL) -> Bool = { _ in true },
      onCompile: @escaping @Sendable () -> Void = {},
      createFileError: @escaping @Sendable (URL) -> NSError? = { _ in nil },
    ) {
      self.compileAndReturnError = compileAndReturnError
      self.execute = execute
      self.compileError = compileError
      self.createSource = createSource
      self.createFile = createFile
      self.onCompile = onCompile
      self.createFileError = createFileError
    }
  }
}
#endif
