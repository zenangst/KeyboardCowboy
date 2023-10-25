import Foundation
import SwiftUI

final class NSEventController: ObservableObject {
  @Published var repeatingKeyDown: Bool = false

  static let shared: NSEventController = .init()

  fileprivate init() {
    NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .keyDown]) { [weak self] event in
      guard let self else { return event }
      if event.type == .keyDown, event.isARepeat {
        repeatingKeyDown = true
      } else {
        repeatingKeyDown = false
      }
      return event
    }
  }
}
