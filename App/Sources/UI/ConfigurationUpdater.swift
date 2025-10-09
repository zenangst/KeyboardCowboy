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
       onStorageUpdate: @escaping (KeyboardCowboyConfiguration, UpdateTransaction) -> Void)
  {
    self.onRender = onRender
    passthroughSubscription = passthrough
      .debounce(for: stride, scheduler: DispatchQueue.main)
      .sink { [weak self] commit in
        switch commit.state {
        case let .configured(configuration):
          onStorageUpdate(configuration, commit.transaction)
          commit.postAction?()
        case .uninitialized:
          break
        }
        self?.state = commit.state
      }
  }

  func subscribe(to publisher: Published<KeyboardCowboyConfiguration>.Publisher) {
    configurationSubscription = publisher
      .compactMap(\.self)
      .sink { [weak self] in
        self?.state = .configured($0)
      }
  }

  func getConfiguration(handler: (KeyboardCowboyConfiguration) -> Void) {
    guard case let .configured(configuration) = state else { return }

    handler(configuration)
  }

  func modifyGroup(using transaction: UpdateTransaction, withAnimation animation: Animation? = nil, handler: (inout WorkflowGroup) -> Void) {
    guard case var .configured(configuration) = state else { return }
    guard configuration.modify(
      groupID: transaction.groupID,
      modify: handler,
    ) else {
      return
    }

    onRender(configuration, transaction, animation)
    passthrough.send(UpdateCommit(.configured(configuration), transaction: transaction))
  }

  func modifyWorkflow(using transaction: UpdateTransaction, withAnimation animation: Animation? = nil, handler: (inout Workflow) -> Void, postAction: ((Workflow.ID) -> Void)? = nil) {
    guard case var .configured(configuration) = state else { return }
    guard configuration.modify(
      groupID: transaction.groupID,
      workflowID: transaction.workflowID,
      modify: handler,
    ) else {
      return
    }

    onRender(configuration, transaction, animation)
    passthrough.send(UpdateCommit(.configured(configuration), transaction: transaction, postAction: {
      postAction?(transaction.workflowID)
    }))
  }

  func modifyCommand(withID commandID: Command.ID, withAnimation animation: Animation? = nil, using transaction: UpdateTransaction, handler: (inout Command) -> Void) {
    guard case var .configured(configuration) = state else { return }
    guard configuration.modify(
      groupID: transaction.groupID,
      workflowID: transaction.workflowID,
      commandID: commandID,
      modify: handler,
    ) else {
      return
    }

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
  let postAction: (() -> Void)?

  init(_ state: ConfigurationUpdater.State,
       transaction: UpdateTransaction,
       postAction: (() -> Void)? = nil)
  {
    self.state = state
    self.transaction = transaction
    self.postAction = postAction
  }
}
