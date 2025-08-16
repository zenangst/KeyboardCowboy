import Foundation

enum RepeatLastWorkflowRunnerError: Error {
  case noPreviousWorkflow
  case noWorkflowRunner
}

@MainActor
final class RepeatLastWorkflowRunner {
  weak var workflowRunner: WorkflowRunner?
  @MainActor
  static var previousWorkflow: Workflow?

  func run() async throws -> String {
    guard let workflow = Self.previousWorkflow else {
      throw RepeatLastWorkflowRunnerError.noPreviousWorkflow
    }

    guard let workflowRunner = workflowRunner else {
      throw RepeatLastWorkflowRunnerError.noWorkflowRunner
    }

    workflowRunner.runCommands(in: workflow)

    return ""
  }

  func setWorkflowRunner(_ newRunner: WorkflowRunner) {
    self.workflowRunner = newRunner
  }
}

