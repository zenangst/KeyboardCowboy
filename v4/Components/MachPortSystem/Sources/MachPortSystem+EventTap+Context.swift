import CoreGraphics

extension MachPortSystem.EventTap {
  // The tap owns this context. The C callback takes a strong local reference
  // before invoking client code, so stopping or destroying the tap in a handler
  // cannot destroy the context while that callback is in flight.
  final class Context {
    let router: MachPortSystem.EventRouter
    let syntheticSignature: Int64
    let eventSource: CGEventSource?
    let handler: (MachPortSystem.InterceptedEvent) -> MachPortSystem.EventDisposition
    let onDisruption: (Disruption) -> Void

    init(configuration: MachPortSystem.TapConfiguration, signature: Int64,
         handler: @escaping (MachPortSystem.InterceptedEvent) -> MachPortSystem.EventDisposition,
         onDisruption: @escaping (Disruption) -> Void) {
      router = .init(syntheticSignature: signature)
      syntheticSignature = signature
      eventSource = CGEventSource(stateID: configuration.sourceState)
      self.handler = handler
      self.onDisruption = onDisruption
    }

    func deliver(type: CGEventType, event: CGEvent) -> CGEvent? {
      switch type {
      case .tapDisabledByTimeout:
        router.reset()
        onDisruption(.timeout)
        return event
      case .tapDisabledByUserInput:
        router.reset()
        onDisruption(.userInput)
        return event
      default:
        return router.route(event, type: type, eventSource: eventSource, handler: handler)
      }
    }
  }
}
