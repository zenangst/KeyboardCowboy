@testable import LogicFramework
import Foundation
import SnapshotTesting
import XCTest

class GroupControllerTests: XCTestCase {
  func testGroupControllerFilterByRules() {
    let xcodeRuleSet = Rule(bundleIdentifiers: ["com.apple.dt.Xcode"])
    let calendarRuleSet = Rule(bundleIdentifiers: ["com.apple.Calendar"])
    let weekDayRuleSet = Rule(days: [.monday, .tuesday, .wednesday, .thursday, .friday])

    let groups = [
      Group(name: "Group: Only when Xcode is active",
            rule: xcodeRuleSet,
            workflows: [Workflow(id: UUID().uuidString, commands: [],
                                 keyboardShortcuts: [],
                                 name: "Xcode workflow")]),
      Group(name: "Group: Only when Calendar is active",
            rule: calendarRuleSet,
            workflows: [Workflow(id: UUID().uuidString, commands: [],
                                 keyboardShortcuts: [],
                                 name: "Calendar workflow")]),
      Group(name: "Group: Global Xcode workflow",
            rule: nil,
            workflows: [Workflow(id: UUID().uuidString, commands: [],
                                 keyboardShortcuts: [],
                                 name: "Open Xcode")]),
      Group(name: "Group: Day-based rule",
            rule: weekDayRuleSet,
            workflows: [Workflow(id: UUID().uuidString, commands: [],
                                 keyboardShortcuts: [],
                                 name: "Open Time tracker")])
    ]

    let controller = GroupsController(groups: groups)

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
