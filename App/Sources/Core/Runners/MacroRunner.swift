import Foundation
import KeyCodes
import MachPort

final class MacroRunner {
  private let bezelId = "com.zenangst.Keyboard-Cowboy.MacroRunner"
  private let coordinator: MacroCoordinator

  init(coordinator: MacroCoordinator) {
    self.coordinator = coordinator
  }

  func run(_ macroAction: MacroAction, machPortEvent: MachPortEvent) async -> String {
    let output: String
    switch macroAction.kind {
    case .record:
      if let recordedEvent = coordinator.recordingEvent {
        coordinator.state = .idle
        if let keyShortcut = coordinator.keyShortcut(for: recordedEvent) {
          output = "Recorded Macro for \(keyShortcut.modifersDisplayValue) \(keyShortcut.key)"
        } else {
          output = "Recorded Macro"
        }
      } else if coordinator.state == .recording {
        coordinator.state = .idle
        output = "Macro Recording Aborted."
      } else {
        coordinator.state = .recording
        output = "Choose Macro key..."
      }
    case .remove:
      coordinator.state = .removing
      output = "Remove Macro key..."
    }

    Task { @MainActor [bezelId] in
      BezelNotificationController.shared.post(.init(id: bezelId, text: output))
    }

    return output
  }
}
