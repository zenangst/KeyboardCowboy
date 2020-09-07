@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class GroupControllerTests: XCTestCase {
  func testGroupControllerFilterByRules() {
    let xcodeApplicationRule: Rule = .application(
      Application(bundleIdentifier: "com.apple.dt.Xcode",
                  name: "Xcode",
                  path: "path/to/Finder"))
    let weekdayRule: Rule = .days([.monday, .tuesday, .wednesday, .thursday, .friday])

    let groups = [
      Group(name: "Group: Only when Xcode is active",
            rules: [xcodeApplicationRule],
            workflows: [Workflow(commands: [], combinations: [], name: "Xcode workflow")]),
      Group(name: "Group: Only when Calendar is active",
            rules: [.application(Application(bundleIdentifier: "com.apple.Calendar",
                                             name: "Calendar",
                                             path: "path/to/Calendar"))],
            workflows: [Workflow(commands: [], combinations: [], name: "Calendar workflow")]),
      Group(name: "Group: Global Xcode workflow",
            rules: [],
            workflows: [Workflow(commands: [], combinations: [], name: "Open Xcode")]),
      Group(name: "Group: Day-based rule",
            rules: [weekdayRule],
            workflows: [Workflow(commands: [], combinations: [], name: "Open Time tracker")])
    ]

    let controller = GroupController(groups: groups)

    assertSnapshot(matching: controller.filterGroups(using: [xcodeApplicationRule]), as: .dump)
    assertSnapshot(matching: controller.filterGroups(using: [.days([.monday])]), as: .dump)
    assertSnapshot(matching: controller.filterGroups(using: [.days([.sunday])]), as: .dump)
  }
}
