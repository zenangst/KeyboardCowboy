import Combine
import Foundation
import SwiftUI

final class LocalEventMonitor: ObservableObject {
  @Published var emptyFlags: Bool = true
  @Published var event: NSEvent?
  @Published var repeatingKeyDown: Bool = false
  private var subscription: AnyCancellable?

  static let shared: LocalEventMonitor = .init()

  fileprivate init() {
    NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
      let result = event.cgEvent?.flags == CGEventFlags.maskNonCoalesced
      self?.emptyFlags = result
      if result {
        self?.event = nil
      }
      return event
    }

    NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .keyDown]) { [weak self] event in
      guard let self else { return event }

      self.event = event

      if event.isARepeat {
        repeatingKeyDown = true
      } else {
        repeatingKeyDown = false
      }
      return event
    }
  }
}
