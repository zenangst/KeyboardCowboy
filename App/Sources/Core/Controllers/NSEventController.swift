import Foundation
import SwiftUI

final class NSEventController: ObservableObject {
  @Published var upKeyEvent: NSEvent?
  @Published var repeatingKeyDown: Bool = false

  static let shared: NSEventController = .init()

  fileprivate init() {
    NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .keyDown]) { [weak self] event in
      guard let self else { return event }

      if event.type == .keyUp {
        self.upKeyEvent = event
      }

      if event.isARepeat {
        repeatingKeyDown = true
      } else {
        repeatingKeyDown = false
      }
      return event
    }
  }
}
