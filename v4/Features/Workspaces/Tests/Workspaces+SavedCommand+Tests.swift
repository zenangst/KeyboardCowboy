import Commands
import Foundation
import Testing
import WorkspacesFeature

private typealias Saved = Workspaces.SavedCommand
private let metadata = #"{"id":"outer","name":"Layout","enabled":false,"delay":40,"notification":"capsule","variableName":"layout"}"#
private let workspace = """
  {"id":"target","applications":[{"bundleIdentifier":"com.example.one","options":["onlyWhenRunning"]},
    {"bundleIdentifier":"com.example.two"}],"tiling":"arrangeDynamicQuarters","hideOtherApps":true,
    "appToggleModifiers":["r@","$"],"defaultForDynamicWorkspace":true}
  """

private func fixture(_ kind: String, _ payload: String) -> String {
  """
  {"bundled":{"kind":{"\(kind)":{"command":\(payload)}},"meta":\(metadata)}}
  """
}

private func decode(_ json: String) throws -> Saved {
  try JSONDecoder().decode(Saved.self, from: Data(json.utf8))
}

private func expectCanonicalRoundTrip(_ saved: Saved, _ json: String) throws {
  func canonical(_ data: Data) throws -> String {
    let object = try JSONSerialization.jsonObject(with: data)
    let sorted = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    return String(decoding: sorted, as: UTF8.self)
  }
  let encoded = try JSONEncoder().encode(saved)
  #expect(try canonical(encoded) == canonical(Data(json.utf8)))
  #expect(try JSONDecoder().decode(Saved.self, from: encoded) == saved)
}

@Test func savedTidyRetainsBundledEnvelopeAndRuleOrder() throws {
  let json = fixture("tidy", """
    {"id":"tidy","rules":[{"bundleIdentifier":"com.example.one","tiling":"left"},
      {"bundleIdentifier":"com.example.one","tiling":"topRight"}]}
    """)
  let saved = try decode(json)
  guard case let .tidy(command) = saved.kind else {
    Issue.record("Expected a saved Tidy command")
    return
  }
  #expect(command.id == "tidy")
  #expect(command.rules.map(\.tiling.rawValue) == ["left", "topRight"])
  #expect(saved.meta.id == "outer")
  try expectCanonicalRoundTrip(saved, json)
}

@Test func savedWorkspaceRetainsMetadataAndProjectsToExpansionInput() throws {
  let json = fixture("workspace", workspace)
  let saved = try decode(json)
  guard case .workspace(let command) = saved.kind else {
    Issue.record("Expected a workspace")
    return
  }
  #expect(saved.meta == .init(delay: 40, id: "outer", name: "Layout", isEnabled: false,
                             notification: .capsule, variableName: "layout"))
  #expect(command.id == "target")
  #expect(command.appToggleModifiers == ["r@", "$"])
  #expect(command.defaultForDynamicWorkspace)
  #expect(command.workspace.tiling == .arrangeDynamicQuarters)
  #expect(command.workspace.hideOtherApps)
  #expect(command.workspace.applications == [.init("com.example.one", onlyWhenRunning: true), .init("com.example.two")])
  try expectCanonicalRoundTrip(saved, json)
}

@Test func legacyBundleIdentifiersTakePrecedenceAndEncodeAsApplications() throws {
  let saved = try decode(fixture("workspace", """
    {"id":"legacy","bundleIdentifiers":["com.example.two","com.example.one"],
     "applications":[{"bundleIdentifier":"com.example.ignored","options":["onlyWhenRunning"]}],
     "hideOtherApps":false}
    """))
  guard case .workspace(let command) = saved.kind else {
    Issue.record("Expected a workspace")
    return
  }
  #expect(command.applications == [.init("com.example.two"), .init("com.example.one")])
  #expect(command.appToggleModifiers.isEmpty && !command.defaultForDynamicWorkspace && command.tiling == nil)
  try expectCanonicalRoundTrip(saved, fixture("workspace", """
    {"id":"legacy","applications":[{"bundleIdentifier":"com.example.two"},{"bundleIdentifier":"com.example.one"}],
     "hideOtherApps":false}
    """))
}

@Test func legacyAssignAndMoveDecodeFromTheirOwnCaseKeys() throws {
  // v3 encoded these keys, but the decoder looked for the sibling `workspace` case instead.
  let assign = fixture("assignToWorkspace", #"{"id":"assign","workspaceID":"target"}"#)
  let assignment = try decode(assign)
  #expect(assignment.kind == .assignToWorkspace(command: .init(id: "assign", workspaceID: "target")))
  try expectCanonicalRoundTrip(assignment, assign)

  let move = fixture("moveToWorkspace", """
    {"id":"move","workspace":\(workspace)}
    """)
  let movement = try decode(move)
  guard case .moveToWorkspace(let command) = movement.kind else {
    Issue.record("Expected a move-to-workspace command")
    return
  }
  #expect(command.id == "move")
  #expect(command.workspace.id == "target")
  #expect(command.workspace.applications.first?.onlyWhenRunning == true)
  try expectCanonicalRoundTrip(movement, move)
  #expect(throws: DecodingError.self) {
    try decode(fixture("workspace", #"{"id":"assign","workspaceID":"target"}"#))
  }
}

@Test func previousWorkspaceKeepsItsLegacyCaseKey() throws {
  let json = fixture("activatePreviousWorkspace", #"{"id":"previous"}"#)
  let saved = try decode(json)
  #expect(saved.kind == .activatePreviousWorkspace(command: .init(id: "previous")))
  try expectCanonicalRoundTrip(saved, json)
}

@Test(arguments: [nil, false] as [Bool?])
func appFocusKeepsTheLegacyBundleKeyAndDefaultsToCreatingWindows(createNewWindow: Bool?) throws {
  let option = createNewWindow.map { #","createNewWindow":\#($0)"# } ?? ""
  let json = fixture("appFocus", """
    {"id":"focus","bundleIdentifer":"com.example.one","hideOtherApps":true,"tiling":"fill"\(option)}
    """)
  let saved = try decode(json)
  #expect(saved.kind == .appFocus(command: .init(
    id: "focus", bundleIdentifier: "com.example.one", hideOtherApps: true,
    createNewWindow: createNewWindow ?? true, tiling: .fill,
  )))
  try expectCanonicalRoundTrip(saved, fixture("appFocus", """
    {"id":"focus","bundleIdentifer":"com.example.one","hideOtherApps":true,"tiling":"fill",
     "createNewWindow":\(createNewWindow ?? true)}
    """))
}
