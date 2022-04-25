import Foundation

final class KeyboardStrokeEngine {
  private var sequence: [KeyShortcut] = .init()
  private var activeWorkflows: [Workflow] = .init()
  private var sessionWorkflows: [Workflow] = .init()

  func activate(_ newWorkflows: [Workflow]) {
    sequence = []
    activeWorkflows = newWorkflows
    sessionWorkflows = newWorkflows
  }

  func respond(to keystroke: KeyShortcut) {
    sequence.append(keystroke)

    var shortcutsToActivate = Set<KeyShortcut>()
    var workflowsToActivate = Set<Workflow>()

    let workflows = sessionWorkflows.filter { workflow in
      guard case let .keyboardShortcuts(shortcuts) = workflow.trigger else { return false }

      let lhs = shortcuts.stringValue
      let rhs = sequence.stringValue

      if lhs.isEmpty { return false }

      if sequence.count < shortcuts.count {
        return lhs.starts(with: rhs)
      } else {
        let perfectMatch = lhs == rhs
        if perfectMatch {
          workflowsToActivate.insert(workflow)
        }
        return perfectMatch
      }
    }

    for workflow in workflows where workflow.isEnabled {
      guard case let .keyboardShortcuts(shortcuts) = workflow.trigger,
            shortcuts.count >= sequence.count
            else { continue }

      guard let validShortcut = shortcuts[sequence.count..<shortcuts.count].first
      else { continue }
      workflowsToActivate.insert(workflow)
      shortcutsToActivate.insert(validShortcut)
    }

    if shortcutsToActivate.isEmpty {
      self.sequence = []
      self.sessionWorkflows = self.activeWorkflows
      // TODO: Run workflow
    } else {
      self.sessionWorkflows = Array(workflowsToActivate)
    }
  }
}

private extension Collection where Element == KeyShortcut {
  var stringValue: String {
    compactMap { $0.stringValue }.joined()
  }
}
