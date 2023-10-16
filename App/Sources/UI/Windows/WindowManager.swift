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
