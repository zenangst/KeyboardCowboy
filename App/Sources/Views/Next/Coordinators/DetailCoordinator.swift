import SwiftUI

final class DetailCoordinator {
  let applicationStore: ApplicationStore
  let contentStore: ContentStore
  let groupStore: GroupStore
  let publisher: DetailPublisher = .init(.empty)

  init(applicationStore: ApplicationStore, contentStore: ContentStore, groupStore: GroupStore) {
      self.applicationStore = applicationStore
      self.contentStore = contentStore
      self.groupStore = groupStore
  }

  func handle(_ action: ContentView.Action) {
    switch action {
    case .selectWorkflow(let content):
      Task { await render(content) }
    default:
      break
    }
  }

  @MainActor
  func handle(_ action: DetailView.Action) {
    switch action {
    case .singleDetailView(let action):
      switch action {
      case .moveCommand(let workflowId, let fromOffsets, let toOffset):
        guard var workflow = groupStore.workflow(withId: workflowId) else { return }
        workflow.commands.move(fromOffsets: fromOffsets, toOffset: toOffset)
        contentStore.updateWorkflows([workflow])
      case .updateName(let name, let workflowId):
        guard var workflow = groupStore.workflow(withId: workflowId) else { return }
        workflow.name = name
        contentStore.updateWorkflows([workflow])
      case .addCommand:
        break
      case .trigger(let action):
        switch action {
        case .addKeyboardShortcut:
          Swift.print("Add keyboard shortcut")
        case .removeKeyboardShortcut:
          Swift.print("Remove keyboard shortcut")
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
    let workflows = groupStore.groups
      .flatMap(\.workflows)
      .filter { ids.contains($0.id) }

    var viewModels: [DetailViewModel] = []
    for workflow in workflows {
      let commands = workflow.commands
        .map { command in
          let kind: DetailViewModel.CommandViewModel.Kind
          let name: String
          switch command {
          case .application(let applicationCommand):
            kind = .application
            name = applicationCommand.application.displayName
          case .builtIn(_):
            kind = .plain
            name = command.name
          case .keyboard(_):
            kind = .plain
            name = command.name
          case .open(let openCommand):
            let appName: String?
            if let app = openCommand.application {
              appName = app.displayName
            } else if let url = URL(string: openCommand.path),
                      let appUrl = NSWorkspace.shared.urlForApplication(toOpen: url),
                      let app = applicationStore.application(at: appUrl) {
              appName = app.displayName
            } else {
              appName = nil
            }

            kind = .open(appName: appName)

            if openCommand.isUrl {
              name = openCommand.path
            } else {
              name = openCommand.path
            }
          case .shortcut(_):
            kind = .plain
            name = command.name
          case .script(let script):
            switch script {
            case .appleScript(_ , _, _, let source),
                 .shell(_ , _, _, let source):
              switch source {
              case .path(let source):
                let fileExtension = (source as NSString).pathExtension
                kind = .script(.path(id: script.id, fileExtension: fileExtension.uppercased()))
              case .inline(_):
                let type: String
                switch script {
                case .shell:
                  type = "sh"
                case .appleScript:
                  type = "scpt"
                }
                kind = .script(.inline(id: script.id, type: type))
              }
            }
            name = command.name
          case .type(_):
            kind = .plain
            name = command.name
          }

          return DetailViewModel.CommandViewModel(
            id: command.id,
            name: name,
            kind: kind,
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
    case .script(let kind):
      return NSWorkspace.shared.icon(forFile: kind.path)
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
