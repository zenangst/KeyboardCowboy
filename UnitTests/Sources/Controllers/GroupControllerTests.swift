@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class GroupControllerTests: XCTestCase {
  func testGroupControllerFilterByRules() {
    let xcodeRuleSet = Rule(applications: [
      Application(bundleIdentifier: "com.apple.dt.Xcode",
                  name: "Xcode",
                  path: "path/to/Xcode")
    ])

    let calendarRuleSet = Rule(applications: [
      Application(bundleIdentifier: "com.apple.Calendar",
                  name: "Calendar",
                  path: "path/to/Calendar")
    ])

    let weekDayRuleSet = Rule(days: [.monday, .tuesday, .wednesday, .thursday, .friday])

    let groups = [
      Group(name: "Group: Only when Xcode is active",
            rule: xcodeRuleSet,
            workflows: [Workflow(commands: [], combinations: [], name: "Xcode workflow")]),
      Group(name: "Group: Only when Calendar is active",
            rule: calendarRuleSet,
            workflows: [Workflow(commands: [], combinations: [], name: "Calendar workflow")]),
      Group(name: "Group: Global Xcode workflow",
            rule: nil,
            workflows: [Workflow(commands: [], combinations: [], name: "Open Xcode")]),
      Group(name: "Group: Day-based rule",
            rule: weekDayRuleSet,
            workflows: [Workflow(commands: [], combinations: [], name: "Open Time tracker")])
    ]

    let controller = GroupController(groups: groups)

    XCTAssertEqual(
      controller.filterGroups(using: xcodeRuleSet).compactMap { $0.name },
      [
        "Group: Only when Xcode is active",
        "Group: Global Xcode workflow"
      ]
    )

    XCTAssertEqual(
      controller.filterGroups(using: Rule(days: [.monday])).compactMap { $0.name },
      [
        "Group: Global Xcode workflow",
        "Group: Day-based rule"
      ]
    )

    XCTAssertEqual(
      controller.filterGroups(using: Rule(days: [.sunday])).compactMap { $0.name },
      ["Group: Global Xcode workflow"]
    )
  }
}
