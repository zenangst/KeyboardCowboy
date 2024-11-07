import Combine
import Foundation
import SwiftUI

final class ConfigurationUpdater: ObservableObject {
  enum State {
    case uninitialized
    case configured(KeyboardCowboyConfiguration)
  }

  private var state: State = .uninitialized

  private var passthrough = PassthroughSubject<KeyboardCowboyConfiguration, Never>()
  private var passthroughSubscription: AnyCancellable?
  private var configurationSubscription: AnyCancellable?

  init(for stride:  DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500),
       onUpdate: @escaping (KeyboardCowboyConfiguration) -> Void) {
    self.passthroughSubscription = passthrough
      .debounce(for: stride, scheduler: DispatchQueue.main)
      .sink { onUpdate($0) }
  }

  func subscribe(to publisher: Published<KeyboardCowboyConfiguration>.Publisher) {
    configurationSubscription = publisher
      .compactMap { $0 }
      .sink { [weak self] in
        self?.state = .configured($0)
      }
  }

  func modifyGroup(using transaction: UpdateTransaction, handler: (inout WorkflowGroup) -> Void) {
    guard case .configured(var configuration) = state else { return }
    configuration.modify(
      groupID: transaction.groupID,
      modify: handler
    )
    passthrough.send(configuration)
  }

  func modifyWorkflow(using transaction: UpdateTransaction, handler: (inout Workflow) -> Void) {
    guard case .configured(var configuration) = state else { return }
    configuration.modify(
      groupID: transaction.groupID,
      workflowID: transaction.workflowID,
      modify: handler
    )
    passthrough.send(configuration)
  }

  func modifyCommand(withID commandID: Command.ID, using transaction: UpdateTransaction, handler: (inout Command) -> Void) {
    guard case .configured(var configuration) = state else { return }
    configuration.modify(
      groupID: transaction.groupID,
      workflowID: transaction.workflowID,
      commandID: commandID,
      modify: handler
    )
    passthrough.send(configuration)
  }
}

final class UpdateTransaction: ObservableObject {
  var groupID: WorkflowGroup.ID
  var workflowID: Workflow.ID

  init(groupID: WorkflowGroup.ID, workflowID: Workflow.ID) {
    self.groupID = groupID
    self.workflowID = workflowID
  }
}
