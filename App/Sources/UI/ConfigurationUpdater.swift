import Combine
import Foundation
import SwiftUI

final class ConfigurationUpdater: ObservableObject {
  enum State {
    case uninitialized
    case configured(KeyboardCowboyConfiguration)
  }

  private var state: State = .uninitialized
  private var passthrough = PassthroughSubject<UpdateCommit, Never>()
  private var passthroughSubscription: AnyCancellable?
  private var configurationSubscription: AnyCancellable?

  private let onRender: (KeyboardCowboyConfiguration, UpdateTransaction, Animation?) -> Void

  init(storageDebounce stride: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500),
       onRender: @escaping (KeyboardCowboyConfiguration, UpdateTransaction, Animation?) -> Void,
       onStorageUpdate: @escaping (KeyboardCowboyConfiguration, UpdateTransaction) -> Void) {
    self.onRender = onRender
    self.passthroughSubscription = passthrough
      .debounce(for: stride, scheduler: DispatchQueue.main)
      .sink { [weak self] commit in
        switch commit.state {
        case .configured(let configuration):
          onStorageUpdate(configuration, commit.transaction)
        case .uninitialized:
          break
        }
        self?.state = commit.state
      }
  }

  func subscribe(to publisher: Published<KeyboardCowboyConfiguration>.Publisher) {
    configurationSubscription = publisher
      .compactMap { $0 }
      .sink { [weak self] in
        self?.state = .configured($0)
      }
  }

  func modifyGroup(using transaction: UpdateTransaction, withAnimation animation: Animation? = nil, handler: (inout WorkflowGroup) -> Void) {
    guard case .configured(var configuration) = state else { return }
    configuration.modify(
      groupID: transaction.groupID,
      modify: handler
    )

    onRender(configuration, transaction, animation)
    passthrough.send(UpdateCommit(.configured(configuration), transaction: transaction))
  }

  func modifyWorkflow(using transaction: UpdateTransaction, withAnimation animation: Animation? = nil, handler: (inout Workflow) -> Void) {
    guard case .configured(var configuration) = state else { return }
    configuration.modify(
      groupID: transaction.groupID,
      workflowID: transaction.workflowID,
      modify: handler
    )

    onRender(configuration, transaction, animation)
    passthrough.send(UpdateCommit(.configured(configuration), transaction: transaction))
  }

  func modifyCommand(withID commandID: Command.ID, withAnimation animation: Animation? = nil, using transaction: UpdateTransaction, handler: (inout Command) -> Void) {
    guard case .configured(var configuration) = state else { return }
    configuration.modify(
      groupID: transaction.groupID,
      workflowID: transaction.workflowID,
      commandID: commandID,
      modify: handler
    )

    onRender(configuration, transaction, animation)
    passthrough.send(UpdateCommit(.configured(configuration), transaction: transaction))
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

struct UpdateCommit {
  let state: ConfigurationUpdater.State
  let transaction: UpdateTransaction

  init(_ state: ConfigurationUpdater.State,
       transaction: UpdateTransaction) {
    self.state = state
    self.transaction = transaction
  }
}
