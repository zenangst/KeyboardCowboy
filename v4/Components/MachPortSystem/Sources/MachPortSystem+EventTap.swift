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

    /// `handler` receives each routed event, including flags changes, once in
    /// run-loop delivery order. Matching synthetic events bypass it; system
    /// disable notifications go exclusively to `onDisruption`.
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

    /// Creates a poster on the owning run loop with this tap's source and
    /// signature. Other taps that must bypass these events need the same
    /// signature. The tap does not have to be installed to create the poster.
    public func makeKeyboardEventPoster() throws -> KeyboardEventPoster {
      checkOwner()
      guard let source = context.eventSource else { throw Failure.eventSourceCreationFailed }

      return KeyboardEventPoster(eventSource: source, syntheticSignature: context.syntheticSignature)
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
      guard operations.isEnabled(newHandle) else {
        operations.stop(newHandle, owner, configuration.runLoopMode)
        throw Failure.enableFailed
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

    /// Makes one recovery attempt, removing the old tap before installing a new
    /// one. On failure it is stopped. The host decides whether to retry.
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
