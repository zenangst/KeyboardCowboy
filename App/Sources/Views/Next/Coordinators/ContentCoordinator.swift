import Combine
import SwiftUI

final class ContentCoordinator {
  private let store: GroupStore
  let publisher: ContentPublisher = ContentPublisher()

  init(_ store: GroupStore) {
    self.store = store
  }

  func handle(_ action: SidebarView.Action) {
    switch action {
    case .onSelect(let groups):
      Task { await render(groups, setSelection: true) }
    default:
      break
    }
  }

  private func render(_ groups: [GroupViewModel], setSelection: Bool) async {
    let ids = groups.map { $0.id }
    let viewModels = store.groups
      .filter { ids.contains($0.id) }
      .flatMap { $0.workflows.asViewModels() }

    let animation: Animation? = nil

    var newSelections: [ContentViewModel]? = nil
    if setSelection, let first = viewModels.first {
      newSelections = [first]
    }

    if publisher.models.isEmpty {
      await publisher.publish(viewModels, selections: newSelections)
    } else {
      await publisher.publish(viewModels, selections: newSelections, withAnimation: animation)
    }
  }
}

private extension Workflow {
  func asViewModel() -> ContentViewModel {
    ContentViewModel(
      id: id,
      name: name,
      images: commands.images(),
      binding: trigger?.binding,
      badge: commands.count > 1 ? commands.count : 0)
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
  func images() -> [ContentViewModel.Image] {
    var images = [ContentViewModel.Image]()
    for (offset, element) in self.enumerated() {
      let convertedOffset = Double(offset)
      switch element {
      case .application(let command):
        images.append(
          ContentViewModel.Image(
            id: command.id,
            offset: convertedOffset,
            nsImage: NSWorkspace.shared.icon(forFile: command.application.path))
        )
      case .builtIn:
        continue
      case .keyboard:
        continue
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
          ContentViewModel.Image(
            id: command.id,
            offset: convertedOffset,
            nsImage: nsImage)
        )
      case .script:
        continue
      case .shortcut:
        continue
      case .type:
        continue
      }
    }

    return images
  }
}

private extension Array where Element == Workflow {
  func asViewModels() -> [ContentViewModel] {
    self.map { $0.asViewModel() }
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
