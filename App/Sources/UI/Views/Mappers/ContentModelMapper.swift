import Bonzai
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
      let key: String = firstMatch.key.count == 1
      ? firstMatch.key.uppercaseFirstLetter()
      : firstMatch.key
      return "\(firstMatch.modifersDisplayValue)\(key)"
    } else if count > 1 {
      return compactMap {
        let key: String = $0.key.count == 1 ? $0.key.uppercaseFirstLetter() : $0.key
        return $0.modifersDisplayValue + key
      }.joined(separator: ",")
    }
    return nil
  }
}

private extension String {
    func uppercaseFirstLetter() -> String {
        guard let firstCharacter = self.first else {
            return self
        }
        let uppercaseFirstCharacter = String(firstCharacter).uppercased()
        let remainingString = String(self.dropFirst())
        return uppercaseFirstCharacter + remainingString
    }
}

private extension Workflow {
  func asViewModel(_ groupName: String?) -> ContentViewModel {
    let commandCount = commands.count
    let binding: String?
    let snippet: String?

    if let trigger  {
      switch trigger {
      case .application(let array):
        binding = nil
        snippet = nil
      case .keyboardShortcuts(let keyboardShortcutTrigger):
        binding = trigger.binding
        snippet = nil
      case .snippet(let snippetTrigger):
        binding = nil
        snippet = snippetTrigger.text
      }

    } else {
      binding = nil
      snippet = nil
    }

    return ContentViewModel(
      id: id,
      groupName: groupName,
      name: name,
      images: commands.images(limit: 1),
      overlayImages: commands.overlayImages(limit: 3),
      binding: binding,
      snippet: snippet,
      badge: commandCount > 1 ? commandCount : 0,
      badgeOpacity: commandCount > 1 ? 1.0 : 0.0,
      isEnabled: isEnabled)
  }
}

private extension Workflow.Trigger {
  var binding: String? {
    switch self {
    case .keyboardShortcuts(let trigger):
      return trigger.shortcuts.binding
    case .application, .snippet:
      return nil
    }
  }
}

private extension Array where Element == Command {
  func overlayImages(limit: Int) -> [ContentViewModel.ImageModel] {
    var images = [ContentViewModel.ImageModel]()

    for (offset, element) in self.enumerated() where element.isEnabled {
      if offset == limit { break }
      let convertedOffset = Double(offset)

      switch element {
      case .open(let command):
        if let application = command.application {
          images.append(ContentViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .icon(.init(bundleIdentifier: application.bundleIdentifier,
                              path: application.path))))
        }
      default:
        continue
      }
    }

    return images
  }

  func images(limit: Int) -> [ContentViewModel.ImageModel] {
    var images = [ContentViewModel.ImageModel]()
    var offset: Int = 0
    for element in self.reversed() where element.isEnabled {
      // Don't render icons for commands that are not enabled.
      if !element.isEnabled { continue }

      if offset == limit { break }

      let convertedOffset = Double(offset)
      switch element {
      case .application(let command):
        images.append(
          ContentViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .icon(.init(bundleIdentifier: command.application.bundleIdentifier,
                              path: command.application.path)))
        )
      case .menuBar(let command):
        images.append(.init(id: command.id, offset: convertedOffset, kind: .command(.menuBar(.init(id: command.id, tokens: command.tokens)))))
      case .builtIn(let command):
        switch command.kind {
        case .macro(let action):
          switch action.kind {
          case .record:
            images.append(.init(id: command.id, offset: convertedOffset, kind: .command(.builtIn(.init(id: command.id, name: command.name, kind: .macro(.record))))))
          case .remove:
            images.append(.init(id: command.id, offset: convertedOffset, kind: .command(.builtIn(.init(id: command.id, name: command.name, kind: .macro(.remove))))))
          }
        case .userMode:
          let path = Bundle.main.bundleURL.path
          images.append(
            ContentViewModel.ImageModel(
              id: command.id,
              offset: convertedOffset,
              kind: .icon(.init(bundleIdentifier: path, path: path)))
          )
        }
      case .mouse(let command):
        images.append(.init(id: command.id, offset: convertedOffset, kind: .command(.mouse(.init(id: command.id, kind: command.kind)))))
      case .keyboard(let keyCommand):
        if let keyboardShortcut = keyCommand.keyboardShortcuts.first {
          images.append(.init(id: keyboardShortcut.id, offset: convertedOffset,
                              kind: .command(.keyboard(.init(id: keyCommand.id, keys: [keyboardShortcut])))))
        }
      case .open(let command):
        let path: String
        if command.isUrl {
          path = "/System/Library/SyncServices/Schemas/Bookmarks.syncschema/Contents/Resources/com.apple.Bookmarks.icns"
        } else {
          path = command.path
        }

        images.append(
          ContentViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .icon(.init(bundleIdentifier: path, path: path)))
        )
      case .script(let script):
        switch script.source {
        case .inline(let source):
          images.append(.init(id: script.id,
                              offset: convertedOffset,
                              kind: .command(.script(.init(id: script.id, source: .inline(source), scriptExtension: script.kind)))))
        case .path(let source):
          images.append(.init(id: script.id,
                              offset: convertedOffset,
                              kind: .command(.script(.init(id: script.id, source: .path(source), scriptExtension: script.kind)))))
        }

      case .shortcut(let shortcut):
        images.append(.init(id: shortcut.id,
                            offset: convertedOffset,
                            kind: .command( .shortcut(.init(id: shortcut.id, shortcutIdentifier: shortcut.shortcutIdentifier)))))
      case .text(let model):
        switch model.kind {
        case .insertText(let command):
          images.append(
            .init(id: command.id,
                  offset: convertedOffset,
                  kind: .command(.text(.init(kind: .type(.init(id: command.id, mode: command.mode, input: command.input))))))
          )
        }
      case .systemCommand(let command):
        images.append(
          ContentViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .command(.systemCommand(.init(id: command.id, kind: command.kind))
          ))
        )
      case .uiElement(let command):
        images.append(.init(id: command.id, offset: convertedOffset, kind: .command(.uiElement(command))))
      case .windowManagement(let command):
        images.append(
          ContentViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .command(.windowManagement(.init(id: command.id, kind: command.kind, animationDuration: command.animationDuration))))
        )
      }
      offset += 1
    }

    return images.reversed()
  }
}
