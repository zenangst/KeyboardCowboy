import SwiftUI

final class DetailCoordinator {
  let store: GroupStore
  let publisher: DetailPublisher = .init(.empty)

  init(_ store: GroupStore) {
    self.store = store
  }

  func handle(_ action: ContentView.Action) {
    switch action {
    case .onSelect(let content):
      Task { await render(content) }
    }
  }

  func handle(_ action: DetailView.Action) {
    switch action {
    case .singleDetailView(let action):
      switch action {
      case .trigger(let action):
        switch action {
        case .addKeyboardShortcut:
          Swift.print("Add keyboard shortcut")
        case .addApplication:
          Swift.print("Add application trigger")
        }
      case .applicationTrigger(let action):
        switch action {
        case .addApplicationTrigger(let application):
          Swift.print("Add application trigger: \(application)")
        case .removeApplicationTrigger(let trigger):
          Swift.print("Remove trigger: \(trigger)")
        }
      }
    }
  }

  private func render(_ content: [ContentViewModel]) async {
    let ids = content.map(\.id)
    let workflows = store.groups
      .flatMap(\.workflows)
      .filter { ids.contains($0.id) }

    var viewModels: [DetailViewModel] = []
    for workflow in workflows {
      let commands = workflow.commands
        .map { command in
          return DetailViewModel.CommandViewModel(
            id: command.id,
            name: command.name,
            image: command.nsImage,
            isEnabled: command.isEnabled
          )
        }

      let viewModel = DetailViewModel(
        id: workflow.id,
        name: workflow.name,
        isEnabled: workflow.isEnabled,
        trigger: workflow.trigger?.asViewModel(),
        commands: commands)
      viewModels.append(viewModel)
    }

    let state: DetailViewState
    if viewModels.count > 1 {
      state = .multiple(viewModels)
    } else if let viewModel = viewModels.first {
      state = .single(viewModel)
    } else {
      state = .empty
    }

    await publisher.publish(state)
  }
}

private extension Command {
  var nsImage: NSImage? {
    switch self {
    case .application(let command):
      return NSWorkspace.shared.icon(forFile: command.application.path)
    case .builtIn:
      return nil
    case .keyboard:
      return nil
    case .open(let command):
      let nsImage: NSImage
      if let application = command.application, command.isUrl {
        nsImage = NSWorkspace.shared.icon(forFile: application.path)
      } else if command.isUrl {
        nsImage = NSWorkspace.shared.icon(forFile: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app")
      } else {
        nsImage = NSWorkspace.shared.icon(forFile: command.path)
      }
      return nsImage
    case .script:
      return nil
    case .shortcut:
      return nil
    case .type:
      return nil
    }
  }
}

extension Workflow.Trigger {
  func asViewModel() -> DetailViewModel.Trigger {
    switch self {
    case .application(let triggers):
      return .applications(
        triggers.map { trigger in
          DetailViewModel.ApplicationTrigger(id: trigger.id,
                                             name: trigger.application.displayName,
                                             image: NSWorkspace.shared.icon(forFile: trigger.application.path),
                                             contexts: trigger.contexts.map {
            switch $0 {
            case .closed:
              return .closed
            case .frontMost:
              return .frontMost
            case .launched:
              return .launched
            }
          })
        }
      )
    case .keyboardShortcuts(let shortcuts):
      let values = shortcuts.map {
        DetailViewModel.KeyboardShortcut(id: $0.id, displayValue: $0.key, modifier: .shift)
      }
      return .keyboardShortcuts(values)
    }
  }
}

extension DetailViewModel.ApplicationTrigger {
}
