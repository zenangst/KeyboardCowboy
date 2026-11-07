#if DEBUG
  import Foundation

  extension Open.System {
    enum Testing {
      @TaskLocal static var mock = Mock()
    }

    struct Mock: Sendable {
      var open: @Sendable (URL, URL?) async throws -> Void = { _, _ in }
      var isDirectory: @Sendable (String) throws -> Bool = { _ in false }
    }
  }
#endif
