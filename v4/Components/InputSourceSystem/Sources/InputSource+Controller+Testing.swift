#if DEBUG
  public extension InputSource.Controller {
    enum Testing {
      @TaskLocal public static var mock = Mock()

      public static func source(id: String, token: String) -> InputSource {
        InputSource(testingID: id, token: token)
      }
    }

    struct Mock: Sendable {
      public enum Unconfigured: Swift.Error { case current, find, select }

      public var current: @MainActor @Sendable () throws -> InputSource
      public var find: @MainActor @Sendable (String, Bool) throws -> InputSource
      public var select: @MainActor @Sendable (InputSource) throws -> Void

      public init(
        current: @escaping @MainActor @Sendable () throws -> InputSource = { throw Unconfigured.current },
        find: @escaping @MainActor @Sendable (String, Bool) throws -> InputSource = { _, _ in throw Unconfigured.find },
        select: @escaping @MainActor @Sendable (InputSource) throws -> Void = { _ in throw Unconfigured.select }
      ) {
        self.current = current
        self.find = find
        self.select = select
      }
    }
  }
#endif
