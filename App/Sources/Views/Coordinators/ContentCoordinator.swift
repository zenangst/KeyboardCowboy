import Combine
import SwiftUI

struct ContentSelectionIds: Identifiable, Hashable {
  var id: Int { groupIds.hashValue + workflowIds.hashValue }

  let groupIds: [GroupViewModel.ID]
  let workflowIds: [ContentViewModel.ID]
}

@MainActor
final class ContentCoordinator {
  static private var appStorage: AppStorageStore = .init()
  private var subscription: AnyCancellable?
  private let store: GroupStore
  private let applicationStore: ApplicationStore

  let selectionPublisher: ContentSelectionIdsPublisher
  let publisher: ContentPublisher = ContentPublisher()

  init(_ store: GroupStore, applicationStore: ApplicationStore,
       selectionPublisher: ContentSelectionIdsPublisher) {
    self.applicationStore = applicationStore
    self.store = store
    self.selectionPublisher = selectionPublisher

    enableInjection(self, selector: #selector(injected(_:)))
  }

  func subscribe(to publisher: Published<WorkflowGroupIds>.Publisher) {
    subscription = publisher
      .dropFirst()
      .debounce(for: .milliseconds(80), scheduler: DispatchQueue.main)
      .sink { [weak self] group in
        self?.render(group.ids, setSelection: true)
      }
  }

  func handle(_ action: DetailView.Action) {
    switch action {
    case .singleDetailView(let action):
      let workflowId = action.workflowId
      guard let groups = store.groups
        .first(where: { $0.workflows
            .map { $0.id }
            .contains(workflowId)
        })
      else {
        return
      }

      let viewModels = groups.workflows.asViewModels(nil)
      var selections = [ContentViewModel]()
      if let matchedSelection = viewModels.first(where: { $0.id == workflowId }) {
        selections = [matchedSelection]
      }

      publisher.publish(viewModels, selections: selections)
    }
  }

  // MARK: Private methods

  @objc private func injected(_ notification: Notification) {
    guard didInject(self, notification: notification) else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
      render(Array(Self.appStorage.groupIds), setSelection: true)
    }
  }

  private func render(_ groupIds: [GroupViewModel.ID], setSelection: Bool) {
    Benchmark.start("ContentCoordinator.render")
    defer {
      Benchmark.finish("ContentCoordinator.render")
    }

    var viewModels = [ContentViewModel]()
    for offset in store.groups.indices {
      let group = store.groups[offset]
      if groupIds.contains(group.id) {
        viewModels.append(contentsOf: group.workflows.asViewModels(group.name))
      }
    }

    var newSelections = [ContentViewModel]()

    if setSelection {
      if publisher.models.isEmpty {
        let matches = viewModels.filter({ Self.appStorage.workflowIds.contains($0.id)})
        if !matches.isEmpty {
          newSelections = matches
        } else if let first = viewModels.first {
          newSelections = [first]
        }
      } else if !publisher.selections.intersection(viewModels).isEmpty {
        newSelections = Array(publisher.selections)
      } else if newSelections.isEmpty, let first = viewModels.first {
        newSelections = [first]
      }
    }

    publisher.publish(viewModels, selections: newSelections)
    selectionPublisher.publish(ContentSelectionIds(groupIds: groupIds,
                                                   workflowIds: newSelections.map(\.id)) )
  }
}

extension Workflow {
  func asViewModel(_ groupName: String?) -> ContentViewModel {
    let commandCount = commands.count
    return ContentViewModel(
      id: id,
      groupName: groupName,
      name: name,
      images: commands.images(),
      binding: trigger?.binding,
      badge: commandCount > 1 ? commandCount : 0,
      badgeOpacity: commandCount > 1 ? 1.0 : 0.0,
      isEnabled: isEnabled)
  }
}

private extension Workflow.Trigger {
  var binding: String? {
    switch self {
    case .keyboardShortcuts(let shortcuts):
      return shortcuts.binding
    case .application:
      return nil
    }
  }
}

private extension Array where Element == Command {
  func images() -> [ContentViewModel.ImageModel] {
    var images = [ContentViewModel.ImageModel]()
    for (offset, element) in self.enumerated() {
      let convertedOffset = Double(offset)
      switch element {
      case .application(let command):
        images.append(
          ContentViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .nsImage(path: command.application.path))
        )
      case .builtIn:
        continue
      case .keyboard(let keyCommand):
        if let keyboardShortcut = keyCommand.keyboardShortcuts.first {
          images.append(.init(id: keyboardShortcut.id, offset: convertedOffset,
                              kind: .command(.keyboard(keys: keyCommand.keyboardShortcuts))))
        }
      case .open(let command):
        let path: String
        if let application = command.application, command.isUrl {
          path = application.path
        } else if command.isUrl {
          path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
        } else {
          path = command.path
        }

        images.append(
          ContentViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .nsImage(path: path))
        )
      case .script(let script):
        switch script.sourceType {
        case .inline(let source):
          images.append(.init(id: script.id,
                              offset: convertedOffset,
                              kind: .command(.script(.inline(id: script.id,
                                                             source: source, scriptExtension: .appleScript)))))

        case .path(let source):
          images.append(.init(id: script.id,
                              offset: convertedOffset,
                              kind: .command(.script(.path(id: script.id,
                                                           source: source,
                                                           scriptExtension: .appleScript)))))
        }
      case .shortcut(let shortcut):
        images.append(.init(id: shortcut.id, offset: convertedOffset, kind: .command(.shortcut)))
      case .type(let type):
        images.append(.init(id: type.id, offset: convertedOffset, kind: .command(.type(input: type.input))))
      }
    }

    return images
  }
}

private extension Array where Element == Workflow {
  func asViewModels(_ groupName: String?) -> [ContentViewModel] {
    var viewModels = [ContentViewModel]()
    viewModels.reserveCapacity(self.count)
    for (offset, model) in self.enumerated() {
      viewModels.append(model.asViewModel(offset == 0 ? groupName : nil))
    }
    return viewModels
  }
}

private extension Array where Element == KeyShortcut {
  var binding: String? {
    if count == 1, let firstMatch = first {
      return "\(firstMatch.modifersDisplayValue)\(firstMatch.key)"
    }
    return nil
  }
}
