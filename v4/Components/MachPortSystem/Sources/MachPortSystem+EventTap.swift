import CoreFoundation
import CoreGraphics

public extension MachPortSystem {
  /// A synchronous event tap confined to the run loop on which it is created.
  /// Start, stop, reload, callbacks and destruction of a running tap must all occur
  /// on that run loop. Keep the owner alive until it has stopped the tap.
  /// This type neither checks nor prompts for permissions. Successful creation
  /// does not prove full monitoring access: the system may silently remove
  /// unauthorized event types from the requested mask. Permission UX belongs to
  /// the host. Avoid strongly capturing the tap or its owner in callbacks, since
  /// those closures are retained until the tap is destroyed.
  final class EventTap {
    private let configuration: TapConfiguration
    private let owner: CFRunLoop
    private let context: Context
    private let operations: Operations
    private var handle: Handle?

    public init(
      configuration: TapConfiguration = .init(),
      syntheticSignature: Int64,
      handler: @escaping (InterceptedEvent) -> EventDisposition,
      onDisruption: @escaping (Disruption) -> Void = { _ in },
    ) {
      self.configuration = configuration
      self.owner = CFRunLoopGetCurrent()
      self.context = Context(
        configuration: configuration,
        signature: syntheticSignature,
        handler: handler,
        onDisruption: onDisruption,
      )
      self.operations = .live
    }

    private func checkOwner() {
      precondition(CFEqual(owner, CFRunLoopGetCurrent()), "EventTap must be used on its owning run loop")
    }

    public var isRunning: Bool {
      checkOwner()
      return handle != nil
    }

    /// Whether the installed tap is enabled, not whether all requested events are authorized.
    public var isEnabled: Bool {
      checkOwner()
      guard let handle else { return false }
      return operations.isEnabled(handle)
    }

    /// The source shared with intercepted events and keyboard posters, if available.
    public var eventSource: CGEventSource? {
      checkOwner()
      return context.eventSource
    }

    /// Idempotent while installed. A disabled tap remains installed until stopped
    /// or reloaded; `isRunning` describes installation, not permission or health.
    public func start() throws {
      checkOwner()
      guard handle == nil else { return }
      guard configuration.options == .defaultTap else { throw Failure.unsupportedTapOptions }
      guard context.eventSource != nil else { throw Failure.eventSourceCreationFailed }
      guard let newHandle = operations.start(configuration, owner, context) else {
        throw Failure.creationFailed
      }

      handle = newHandle
    }

    public func stop() {
      checkOwner()
      guard let oldHandle = handle else { return }

      handle = nil
      operations.stop(oldHandle, owner, configuration.runLoopMode)
      context.router.reset()
    }

    /// Removes the old tap before attempting a new one. On failure it is stopped.
    public func reload() throws {
      checkOwner()
      stop()
      try start()
    }

    deinit {
      if let handle {
        precondition(CFEqual(owner, CFRunLoopGetCurrent()), "Stop EventTap on its owning run loop before releasing it")
        operations.stop(handle, owner, configuration.runLoopMode)
      }
    }

    #if DEBUG
    init(
      configuration: TapConfiguration = .init(),
      syntheticSignature: Int64,
      handler: @escaping (InterceptedEvent) -> EventDisposition,
      onDisruption: @escaping (Disruption) -> Void = { _ in },
      operations: Operations,
    ) {
      self.configuration = configuration
      self.owner = CFRunLoopGetCurrent()
      self.context = Context(
        configuration: configuration,
        signature: syntheticSignature,
        handler: handler,
        onDisruption: onDisruption,
      )
      self.operations = operations
    }
    #endif
  }
}
