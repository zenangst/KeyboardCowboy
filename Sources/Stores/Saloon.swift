import Combine
import Foundation
import SwiftUI

let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil

@MainActor
final class Saloon: ObservableObject {
  @Published var preferences: AppPreferences

  private let storage: Storage
  private var subscription: AnyCancellable?

  private(set) var applicationStore = ApplicationStore()
  private(set) var groupStore = WorkflowGroupStore()
  @Published var selectedGroups = [WorkflowGroup]()
  @Published var selectedWorkflows = [Workflow]()

  @AppStorage("selectedGroupIds") var selectedGroupIds = [String]()
  @AppStorage("selectedWorkflowIds") var selectedWorkflowIds = [String]()

  init(_ preferences: AppPreferences = .designTime()) {
    self.preferences = preferences
    self.storage = Storage(preferences.storageConfiguration)
    Task {
      if preferences.hideAppOnLaunch {
        NSApp.hide(self)
      }
      self.groupStore.groups = try await storage.load()
      self.storage.subscribe(to: self.groupStore.$groups)
      self.subscribe(to: self.groupStore.$groups)

      // Remove ids that could be stored in `AppStorage`
      let validGroupIds = groupStore.groups.compactMap({ $0.id })
      selectedGroupIds.removeAll(where: { !validGroupIds.contains($0) })
    }
  }

  func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    subscription = publisher
      .throttle(for: 0.1, scheduler: RunLoop.main, latest: true)
      .sink { [weak self] groups in
        guard let self = self else { return }
        self.selectedGroups = groups.filter({
          self.selectedGroupIds.contains($0.id)
        })
        self.selectedWorkflows = self.selectedGroups
          .flatMap({ $0.workflows })
          .filter({
            self.selectedWorkflowIds.contains($0.id)
          })
    }
  }
}
