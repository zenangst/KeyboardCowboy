import Foundation
import SwiftUI

final class NSEventController: ObservableObject {
  @Published var keyDown: Bool = false

  static let shared: NSEventController = .init()

  fileprivate init() {
    NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .keyDown]) { [weak self] event in
      guard let self else { return event }
      if event.type == .keyDown, event.isARepeat {
        keyDown = true
      } else {
        keyDown = false
      }
      return event
    }
  }
}
