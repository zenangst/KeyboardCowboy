import Combine
import Foundation
import SwiftUI

final class LocalEventMonitor: ObservableObject {
  @Published var emptyFlags: Bool = true
  @Published var event: NSEvent?
  @Published var repeatingKeyDown: Bool = false
  @Published var mouseDown: Bool = false
  private var subscription: AnyCancellable?
  private var mouseMonitor: Any?
  private var keyMonitor: Any?

  @MainActor
  static let shared: LocalEventMonitor = .init()

  fileprivate init() {
    let mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .leftMouseDown, .leftMouseUp]) { [weak self] event in
      guard let self else { return event }

      switch event.type {
      case .leftMouseUp:
        mouseDown = false
      case .leftMouseDown:
        mouseDown = true
      case .flagsChanged:
        let result = event.cgEvent?.flags == CGEventFlags.maskNonCoalesced
        emptyFlags = result
        if result {
          self.event = nil
        }
      default:
        break
      }
      return event
    }
    self.mouseMonitor = mouseMonitor

    let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .keyDown]) { [weak self] event in
      guard let self else { return event }

      self.event = event

      if event.isARepeat {
        repeatingKeyDown = true
      } else {
        repeatingKeyDown = false
      }
      return event
    }
    self.keyMonitor = keyMonitor
  }

  deinit {
    if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
    if let mouseMonitor { NSEvent.removeMonitor(mouseMonitor) }
  }
}
