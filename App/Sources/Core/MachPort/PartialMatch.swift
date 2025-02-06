struct PartialMatch: Sendable {
  let rawValue: String
  let workflow: Workflow?
  
  init(rawValue: String, workflow: Workflow? = nil) {
    self.rawValue = rawValue
    self.workflow = workflow
  }
  
  static func `default`() -> PartialMatch {
    PartialMatch(rawValue: ".")
  }
}
