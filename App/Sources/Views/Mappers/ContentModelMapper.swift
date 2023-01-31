import Foundation

final class ContentModelMapper {
  func map(_ workflow: Workflow) -> ContentViewModel {
    workflow.asViewModel(nil)
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

private extension Workflow {
  func asViewModel(_ groupName: String?) -> ContentViewModel {
    let commandCount = commands.count
    let binding: String?
    if let trigger, let triggerBinding = trigger.binding {
      binding = triggerBinding
    } else {
      binding = nil
    }

    return ContentViewModel(
      id: id,
      groupName: groupName,
      name: name,
      images: commands.images(),
      binding: binding,
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
            kind: .icon(path: command.application.path))
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
            kind: .icon(path: path))
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
