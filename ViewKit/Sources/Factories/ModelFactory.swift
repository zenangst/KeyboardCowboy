import Foundation

class ModelFactory {
  func group() -> Group {
    Group(
      name: "Developer tools",
      workflows: [
        workflow()
      ]
    )
  }

  func workflow() -> Workflow {
    Workflow(
      name: "Open Developer tools",
      combinations: [],
      commands: [
        Command(name: "Open instruments"),
        Command(name: "Open terminal")
      ]
    )
  }
}
