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

      let viewModels = groups.workflows.asViewModels()
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
    var workflowIds = [Workflow.ID]()
    let workflows = store.groups
      .filter {
        if groupIds.contains($0.id) {
          workflowIds.append($0.id)
          return true
        }
       return false
      }
      .flatMap(\.workflows)

    let viewModels = workflows.asViewModels()
    var animation: Animation? = nil
    var newSelections = [ContentViewModel]()

    if setSelection {
      let old = publisher.models
      let new = viewModels
      let diffs = new.difference(from: old).inferringMoves()

      if !old.isEmpty, new.count > 1 {
        for diff in diffs {
          if case .insert(_, let element, let associated) = diff,
             associated == nil {
              newSelections.append(element)
              animation = .default
          }
          if newSelections.count > 1 {
            newSelections = []
            animation = nil
            break
          }
        }
      }

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

    if let animation {
        withAnimation(animation) {
          publisher.publish(viewModels, selections: newSelections)
        }
    } else {
      publisher.publish(viewModels, selections: newSelections)
    }

    selectionPublisher.publish(ContentSelectionIds(groupIds: groupIds,
                                                   workflowIds: newSelections.map(\.id)) )
  }
}

extension Workflow {
  func asViewModel() -> ContentViewModel {
    ContentViewModel(
      id: id,
      name: name,
      images: commands.images(),
      binding: trigger?.binding,
      badge: commands.count > 1 ? commands.count : 0,
      badgeOpacity: commands.count > 1 ? 1.0 : 0.0,
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
            kind: .nsImage(NSWorkspace.shared.icon(forFile: command.application.path)))
        )
      case .builtIn:
        continue
      case .keyboard(let keyCommand):
        if let keyboardShortcut = keyCommand.keyboardShortcuts.first {
          images.append(.init(id: keyboardShortcut.id, offset: convertedOffset,
                              kind: .command(.keyboard(keys: keyCommand.keyboardShortcuts))))
        }
      case .open(let command):
        let nsImage: NSImage
        if let application = command.application, command.isUrl {
          nsImage = NSWorkspace.shared.icon(forFile: application.path)
        } else if command.isUrl {
          nsImage = NSWorkspace.shared.icon(forFile: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app")
        } else {
          nsImage = NSWorkspace.shared.icon(forFile: command.path)
        }

        images.append(
          ContentViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .nsImage(nsImage))
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
  func asViewModels() -> [ContentViewModel] {
    var viewModels = [ContentViewModel]()
    viewModels.reserveCapacity(self.count)
    for model in self {
      viewModels.append(model.asViewModel())
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
