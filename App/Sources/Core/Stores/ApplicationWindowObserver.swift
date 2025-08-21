import ApplicationServices
import AXEssibility
import Cocoa
import Combine

final class ApplicationWindowObserver {
  nonisolated(unsafe) static var isEnabled: Bool = true
  var subscription: AnyCancellable?
  var observers = [AccessibilityObserver]()

  var frontMostApplicationDidCreateWindow: (() -> Void)?
  var frontMostApplicationDidCloseWindow: (() -> Void)?

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    subscription = publisher.sink { [weak self] application in
      guard let self, Self.isEnabled else { return }

      self.process(application)
    }
  }

  private func process(_ application: UserSpace.Application) {
    observers.forEach { $0.removeObserver() }
    observers.removeAll()

    let app = AppAccessibilityElement(application.ref.processIdentifier)
    let id = UUID()

    do {
      let pointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

      if let observer = app.observe(.windowCreated, element: app.reference, id: id, pointer: pointer, callback: { _, element, _, pointer in
        guard let pointer else { return }

        let controller = Unmanaged<ApplicationWindowObserver>
          .fromOpaque(pointer)
          .takeUnretainedValue()
        let app = AppAccessibilityElement(element)

        if app.pid == NSWorkspace.shared.frontmostApplication?.processIdentifier {
          controller.frontMostApplicationDidCreateWindow?()
        }

      }) {
        observers.append(observer)
      }

      if let observer = app.observe(.closed, element: app.reference, id: id, pointer: pointer, callback: { _, element, _, pointer in
        guard let pointer else { return }

        let controller = Unmanaged<ApplicationWindowObserver>
          .fromOpaque(pointer)
          .takeUnretainedValue()
        let app = AppAccessibilityElement(element)

        if app.pid == NSWorkspace.shared.frontmostApplication?.processIdentifier {
          controller.frontMostApplicationDidCloseWindow?()
        }
      }) {
        observers.append(observer)
      }
    }
  }
}
