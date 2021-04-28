@testable import LogicFramework
@testable import ModelKit
import Foundation
import SnapshotTesting
import XCTest

class GroupControllerTests: XCTestCase {
  // swiftlint:disable function_body_length
  func testGroupControllerFilterByRules() {
    let xcodeRuleSet = Rule(bundleIdentifiers: ["com.apple.dt.Xcode"])
    let calendarRuleSet = Rule(bundleIdentifiers: ["com.apple.Calendar"])
    let weekDayRuleSet = Rule(days: [.monday, .tuesday, .wednesday, .thursday, .friday])

    let groups = [
      Group(name: "Group: Only when Xcode is active",
            rule: xcodeRuleSet,
            workflows: [
              Workflow(
                id: UUID().uuidString,
                name: "Xcode workflow",
                trigger: .keyboardShortcuts([]),
                commands: []
              )]),
      Group(name: "Group: Only when Calendar is active",
            rule: calendarRuleSet,
            workflows: [
              Workflow(
                id: UUID().uuidString,
                name: "Calendar workflow",
                trigger: .keyboardShortcuts([]),
                commands: []
                )]),
      Group(name: "Group: Global Xcode workflow",
            rule: nil,
            workflows: [
              Workflow(
                id: UUID().uuidString,
                name: "Open Xcode",
                trigger: .keyboardShortcuts([]),
                commands: []
              )]),
      Group(name: "Group: Day-based rule",
            rule: weekDayRuleSet,
            workflows: [
              Workflow(
                id: UUID().uuidString,
                name: "Open Time tracker",
                trigger: .keyboardShortcuts([]),
                commands: []
              )])
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
