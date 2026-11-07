#if DEBUG
  import Foundation

  extension Open.System {
    enum Testing {
      @TaskLocal static var mock = Mock()
    }

    struct Mock: Sendable {
      var open: @Sendable (URL, URL?) async throws -> Void = { _, _ in }
      var openDefault: @Sendable (URL) -> Bool = { _ in false }
      var isDirectory: @Sendable (String) throws -> Bool = { _ in false }
      var firstRunningProcess: @Sendable (String) -> pid_t? = { _ in nil }
      var activate: @Sendable (pid_t) -> Bool = { _ in false }
    }
  }
#endif
