import XCTest
@testable import Keyboard_Cowboy

final class KeyboardShortcutsControllerTests: XCTestCase {
  func testLookupInLargeCollection() {
    let controller = KeyboardShortcutsController()
    let groups = generateGroups(10, workflows: 50, keyboardShortcuts: 20)

    controller.cache(groups)

    var offset = 0
    let initialKey = KeyShortcut(key: "group-id-9-workflow-keyboard-shortcut-key-0")
    let result = recursiveLookup(controller, keyShortcut: initialKey, offset: &offset)
    XCTAssertTrue(result)
  }

  // TODO: Add additional tests
  // We should add tests that cover binding workflows
  // that are bound to the frontmost application.


  // MARK: - Private methods

  private func recursiveLookup(_ controller: KeyboardShortcutsController,
                               keyShortcut: KeyShortcut,
                               offset: inout Int,
                               partial: PartialMatch = .init(rawValue: ".")) -> Bool {
    let result = controller.lookup(keyShortcut, bundleIdentifier: "", partialMatch: partial)

    switch result {
    case .exact:
      return true
    case .partialMatch(let partial):
      offset += 1
      let key = removeLastEntry(from: keyShortcut.key) + "-\(offset)"
      return recursiveLookup(controller,
                             keyShortcut: .init(key: key),
                             offset: &offset, partial: partial)
    case .none:
      return false
    }
  }

  private func removeLastEntry(from string: String) -> String {
    var components = string.components(separatedBy: "-")
    components.removeLast()
    return components.joined(separator: "-")
  }

  private func generateGroups(_ groups: Int,
                              workflows: Int,
                              keyboardShortcuts: Int) -> [WorkflowGroup] {
    (0..<groups).map {
      WorkflowGroup(id: "group-id-\($0)",
                    name: "group-name-\($0)",
                    workflows: generateWorkflows(
                      workflows,
                      keyboardShortcuts: keyboardShortcuts,
                      prefix: "group-id-\($0)"))
    }
  }

  private func generateWorkflows(_ number: Int,
                                 keyboardShortcuts: Int,
                                 prefix: String) -> [Workflow] {
    (0..<number).map {
      let newPrefix = "\(prefix)-workflow"
      return Workflow(id: "\(newPrefix)-id-\($0)",
                      name: "\(newPrefix)-name-\($0)",
                      trigger: Workflow.Trigger.keyboardShortcuts(.init(shortcuts: generateTriggers(keyboardShortcuts, prefix: newPrefix))))
    }
  }

  private func generateTriggers(_ number: Int, prefix: String) -> [KeyShortcut] {
    (0..<number).map {
      let newPrefix = "\(prefix)-keyboard-shortcut"
      return KeyShortcut(id: "\(newPrefix)-id-\($0)",
                         key: "\(newPrefix)-key-\($0)")
    }
  }
}
