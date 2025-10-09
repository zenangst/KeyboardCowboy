import Bonzai
import Foundation

final class GroupDetailViewModelMapper {
  func map(_ workflow: Workflow, groupId: String) -> GroupDetailViewModel {
    workflow.asViewModel(nil, groupId: groupId)
  }
}

private extension [Workflow] {
  func asViewModels(_ groupName: String?, groupId: String) -> [GroupDetailViewModel] {
    var viewModels = [GroupDetailViewModel]()
    viewModels.reserveCapacity(count)
    for (offset, model) in enumerated() {
      viewModels.append(model.asViewModel(offset == 0 ? groupName : nil, groupId: groupId))
    }
    return viewModels
  }
}

private extension [KeyShortcut] {
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
    guard let firstCharacter = first else {
      return self
    }

    let uppercaseFirstCharacter = String(firstCharacter).uppercased()
    let remainingString = String(dropFirst())
    return uppercaseFirstCharacter + remainingString
  }
}

private extension Workflow {
  func asViewModel(_ groupName: String?, groupId: String) -> GroupDetailViewModel {
    let commandCount = commands.count
    let viewModelTrigger: GroupDetailViewModel.Trigger?
    viewModelTrigger = switch trigger {
    case .application: .application("foo")
    case let .keyboardShortcuts(trigger): .keyboard(trigger.shortcuts.binding ?? "")
    case let .snippet(snippetTrigger): .snippet(snippetTrigger.text)
    case .modifier: .none
    case .none: nil
    }

    let execution: GroupDetailViewModel.Execution = switch execution {
    case .concurrent: .concurrent
    case .serial: .serial
    }

    return GroupDetailViewModel(
      id: id,
      groupId: groupId,
      groupName: groupName,
      name: name,
      images: commands.images(limit: 1),
      overlayImages: commands.overlayImages(limit: 3),
      trigger: viewModelTrigger,
      execution: execution,
      badge: commandCount > 1 ? commandCount : 0,
      badgeOpacity: commandCount > 1 ? 1.0 : 0.0,
      isEnabled: isEnabled,
    )
  }
}

private extension Workflow.Trigger {
  var binding: String? {
    switch self {
    case let .keyboardShortcuts(trigger):
      trigger.shortcuts.binding
    case .application, .snippet, .modifier:
      nil
    }
  }
}

private extension [Command] {
  func overlayImages(limit: Int) -> [GroupDetailViewModel.ImageModel] {
    var images = [GroupDetailViewModel.ImageModel]()

    for (offset, element) in enumerated() where element.isEnabled {
      if offset == limit { break }
      let convertedOffset = Double(offset)

      switch element {
      case let .open(command):
        if let application = command.application {
          images.append(GroupDetailViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .icon(.init(bundleIdentifier: application.bundleIdentifier,
                              path: application.path)),
          ))
        }
      default:
        continue
      }
    }

    return images
  }

  func images(limit: Int) -> [GroupDetailViewModel.ImageModel] {
    var images = [GroupDetailViewModel.ImageModel]()
    var offset = 0
    for element in reversed() where element.isEnabled {
      // Don't render icons for commands that are not enabled.
      if !element.isEnabled { continue }

      if offset == limit { break }

      let convertedOffset = Double(offset)
      switch element {
      case let .application(command):
        images.append(
          GroupDetailViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .icon(.init(bundleIdentifier: command.application.bundleIdentifier,
                              path: command.application.path)),
          ),
        )
      case .menuBar: images.append(.menubar(element, offset: convertedOffset))
      case let .builtIn(command): images.append(.builtIn(element, kind: command.kind, offset: convertedOffset))
      case let .bundled(command):
        switch command.kind {
        case .assignToWorkspace, .moveToWorkspace: fatalError()
        case .activatePreviousWorkspace: images.append(.bundled(element, offset: convertedOffset, kind: .activatePreviousWorkspace))
        case .appFocus: images.append(.bundled(element, offset: convertedOffset, kind: .appFocus))
        case .workspace: images.append(.bundled(element, offset: convertedOffset, kind: .workspace))
        case .tidy: images.append(.bundled(element, offset: convertedOffset, kind: .tidy))
        }
      case .mouse:
        images.append(.mouse(element, offset: convertedOffset))
      case let .keyboard(keyCommand):
        switch keyCommand.kind {
        case let .key(keyCommand):
          if let keyboardShortcut = keyCommand.keyboardShortcuts.first {
            images.append(.keyboard(element, string: keyboardShortcut.key, offset: convertedOffset))
          }
        case .inputSource:
          images.append(.inputSource(element, offset: convertedOffset))
        }
      case let .open(command):
        let path: String = if let appPath = command.application?.path {
          appPath
        } else if command.isUrl {
          "/System/Library/SyncServices/Schemas/Bookmarks.syncschema/Contents/Resources/com.apple.Bookmarks.icns"
        } else {
          command.path
        }

        images.append(
          GroupDetailViewModel.ImageModel(
            id: command.id,
            offset: convertedOffset,
            kind: .icon(.init(bundleIdentifier: path, path: path)),
          ),
        )
      case let .script(command): images.append(.script(element, source: command.source, offset: convertedOffset))
      case .shortcut: images.append(.shortcut(element, offset: convertedOffset))
      case let .text(model):
        switch model.kind {
        case .insertText: images.append(.text(element, kind: .insertText, offset: convertedOffset))
        }
      case let .systemCommand(command): images.append(.systemCommand(element, kind: command.kind, offset: convertedOffset))
      case .uiElement: images.append(.uiElement(element, offset: convertedOffset))
      case let .windowFocus(command): images.append(.windowFocus(element, kind: command.kind, offset: convertedOffset))
      case .windowManagement: images.append(.windowManagement(element, offset: convertedOffset))
      case let .windowTiling(command): images.append(.windowTiling(element, kind: command.kind, offset: convertedOffset))
      }
      offset += 1
    }

    return images.reversed()
  }
}
