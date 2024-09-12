import ApplicationServices
import AXEssibility
import Combine

final class ApplicationWindowObserver {
  nonisolated(unsafe) static var isEnabled: Bool = false
  var subscription: AnyCancellable?
  var observers = [ApplicationAccessibilityObserver]()

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    subscription = publisher.sink { [weak self] application in
      guard let self, Self.isEnabled else { return }
      self.process(application)
    }
  }

  private func process(_ application: UserSpace.Application) {
    observers.forEach {
      $0.removeObserver()
    }
    observers.removeAll()

    let app = AppAccessibilityElement(application.ref.processIdentifier)
    let id = UUID()
    do {
      if let observer = app.observe(.focusedWindowChanged, id: id, callback: { observer, element, notification, data in
        print("element", notification as String)
      }) {
        observers.append(observer)
      }
    }

//    do {
//      let bridge = ObserverBridge(id: id, app: app, object: self)
//      let pointer = UnsafeMutableRawPointer(Unmanaged.passRetained(bridge).toOpaque())
//      if let observer = app.observe(.closed, id: id, pointer: pointer, callback: { observer, element, notification, data in
//        guard let data else { return }
//        let unmanaged = Unmanaged<ObserverBridge<ApplicationWindowObserver>>
//          .fromOpaque(data)
//          .takeUnretainedValue()
//        let instance = unmanaged.object
//        let app = unmanaged.app
//        var offsets = IndexSet()
//        let anyElement = AppAccessibilityElement(element)
//        for (offset, registeredObserver) in instance.observers.enumerated() {
//          if registeredObserver.id == unmanaged.id {
//            offsets.insert(offset)
//            registeredObserver.removeObserver()
//            print("removed", app.title, registeredObserver.id, registeredObserver.notification)
//          }
//        }
//        instance.observers.remove(atOffsets: offsets)
//      }) {
//        observers.append(observer)
//      }
//    }

    do {
      if let observer = app.observe(.windowCreated, id: id, callback: { observer, element, notification, data in
        print("element", notification as String)
      }) {
        observers.append(observer)
      }
    }
  }
}

fileprivate final class ObserverBridge<T: AnyObject> {
  let id: UUID
  let object: T
  let app: AppAccessibilityElement

  init(id: UUID, app: AppAccessibilityElement, object: T) {
    self.id = id
    self.app = app
    self.object = object
  }
}
