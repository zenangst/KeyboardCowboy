import Combine
import Cocoa
import Foundation
import MachPort

final class StatsCoordinator {
  private var subscription: AnyCancellable?
  static let shared = StatsCoordinator()

  private init() { }

  func subscribe(to publisher: Published<MachPortEvent?>.Publisher) {
    subscription = publisher
      .compactMap({ $0 }).sink { [weak self] event in
      self?.handle(event)
    }
  }

  func handle(_ event: MachPortEvent) {
    guard let runningApplication = NSWorkspace.shared.frontmostApplication,
          let localizedName = runningApplication.localizedName,
          event.type == .keyDown else { return }

    let date = Date()
    let shift = event.event.flags.contains(.maskShift) ? "shift" : ""
    let control = event.event.flags.contains(.maskControl) ? "control" : ""
    let option = event.event.flags.contains(.maskAlternate) ? "option" : ""
    let command = event.event.flags.contains(.maskCommand) ? "command" : ""

    /*
     Is this what you want?
     :)
     */

    print(date, localizedName, event.keyCode, shift, control, option, command)
  }
}
