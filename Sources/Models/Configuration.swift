struct Configuration: Identifiable, Codable, Hashable {
  var id: String
  var name: String
  var groups: [WorkflowGroup]
}
