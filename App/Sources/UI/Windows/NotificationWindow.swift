import AppKit
import Combine
import SwiftUI

final class WindowManager: ObservableObject {
  private let passthrough = PassthroughSubject<Void, Never>()
  private var subscription: AnyCancellable?
  weak var window: NSWindow?

  init(subscription: AnyCancellable? = nil, window: NSWindow? = nil) {
    self.subscription = subscription
    self.window = window
  }

  func cancelClose() {
    subscription?.cancel()
  }

  func close(after stride: DispatchQueue.SchedulerTimeType.Stride, then: @escaping () -> Void = {}) {
    subscription = passthrough
      .debounce(for: stride, scheduler: DispatchQueue.main)
      .sink { [window] in
        window?.close()
        then()
      }
    passthrough.send()
  }
}

final class NotificationWindow<Content>: NSPanel where Content: View {
  private let manager: WindowManager
  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }

  convenience init(contentRect: CGRect,
                   content rootView: @autoclosure @escaping () -> Content) {
    self.init(contentRect: contentRect, content: { rootView() })
  }

  init(contentRect: CGRect,
       content rootView: @escaping () -> Content) {
    self.manager = WindowManager()
    super.init(contentRect: contentRect, styleMask: [
      .borderless, .nonactivatingPanel
    ], backing: .buffered, defer: false)

    self.animationBehavior = .utilityWindow
    self.collectionBehavior.insert(.fullScreenAuxiliary)
    self.isOpaque = false
    self.isFloatingPanel = true
    self.isMovable = false
    self.isMovableByWindowBackground = false
    self.level = .screenSaver
    self.becomesKeyOnlyIfNeeded = true
    self.backgroundColor = .clear
    self.acceptsMouseMovedEvents = false

    self.manager.window = self

    let rootView = rootView()
      .ignoresSafeArea()
      .environmentObject(manager)
      .padding()

    self.contentViewController = NSHostingController(rootView: rootView)
  }
}

