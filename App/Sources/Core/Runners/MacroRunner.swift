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
    let currentState = await coordinator.state
    switch macroAction.kind {
    case .record:
      if let recordedEvent = await coordinator.recordingEvent {
        await coordinator.setState(.idle)
        if let keyShortcut = await coordinator.keyShortcut(for: recordedEvent) {
          output = "Recorded Macro for \(keyShortcut.modifersDisplayValue) \(keyShortcut.key)"
        } else {
          output = "Recorded Macro"
        }
      } else if currentState == .recording {
        await coordinator.setState(.idle)
        output = "Macro Recording Aborted."
      } else {
        await coordinator.setState(.recording)
        output = "Choose Macro key..."
      }
    case .remove:
      await coordinator.setState(.removing)
      output = "Remove Macro key..."
    }

    Task { @MainActor [bezelId] in
      BezelNotificationController.shared.post(.init(id: bezelId, text: output))
    }

    return output
  }
}
