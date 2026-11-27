import Testing
import WorkspacesFeature

@Test func assignmentPrependsOutsideStageManagerAndReplacesInsideIt() {
  var membership = Workspaces.Membership()
  #expect(membership.bundleIdentifiers(for: "unknown").isEmpty)
  for app in ["first", "second", "first"] {
    membership.assign(app, to: "workspace", stageManagerEnabled: false)
  }
  membership.assign("first", to: "other", stageManagerEnabled: false)
  #expect(membership.bundleIdentifiers(for: "workspace") == ["first", "second", "first"])

  membership.assign("stage", to: "workspace", stageManagerEnabled: true)
  #expect(membership.bundleIdentifiers(for: "workspace") == ["stage"])
  #expect(membership.bundleIdentifiers(for: "other") == ["first"])
}

@Test(arguments: [false, true])
func movingTransfersAllOccurrencesAndTogglesOffTargetMembership(stageManagerEnabled: Bool) {
  var membership = Workspaces.Membership()
  for app in ["moving", "keep", "moving"] {
    membership.assign(app, to: "source", stageManagerEnabled: false)
  }
  membership.assign("moving", to: "other", stageManagerEnabled: false)
  membership.assign("resident", to: "destination", stageManagerEnabled: false)

  #expect(membership.moveOrRemove("moving", to: "destination", stageManagerEnabled: stageManagerEnabled) == .added)
  #expect(membership.bundleIdentifiers(for: "source") == ["keep"])
  #expect(membership.bundleIdentifiers(for: "other").isEmpty)
  #expect(membership.bundleIdentifiers(for: "destination") == (stageManagerEnabled ? ["moving"] : ["moving", "resident"]))

  membership.assign("moving", to: "other", stageManagerEnabled: false)
  #expect(membership.moveOrRemove("moving", to: "destination", stageManagerEnabled: stageManagerEnabled) == .removed)
  #expect(membership.bundleIdentifiers(for: "source") == ["keep"])
  #expect(membership.bundleIdentifiers(for: "other").isEmpty)
  #expect(membership.bundleIdentifiers(for: "destination") == (stageManagerEnabled ? [] : ["resident"]))
}

@Test func pruningPreservesSurvivorOrderAndFocusOnlyReordersTheCurrentWorkspace() {
  var membership = Workspaces.Membership()
  for workspace in ["current", "other"] {
    for app in ["focus", "last", "closed", "focus", "first"] {
      membership.assign(app, to: workspace, stageManagerEnabled: false)
    }
  }
  membership.assign("closed", to: "emptied", stageManagerEnabled: false)

  membership.prune(runningBundleIdentifiers: ["first", "focus", "last"])
  #expect(membership.bundleIdentifiers(for: "emptied").isEmpty)
  #expect(membership.bundleIdentifiers(for: "current") == ["first", "focus", "last", "focus"])
  membership.recordFocus("unknown", in: "current")
  #expect(membership.bundleIdentifiers(for: "current") == ["first", "focus", "last", "focus"])
  membership.recordFocus("focus", in: "current")
  #expect(membership.bundleIdentifiers(for: "current") == ["first", "last", "focus", "focus"])
  #expect(membership.bundleIdentifiers(for: "other") == ["first", "focus", "last", "focus"])
}
