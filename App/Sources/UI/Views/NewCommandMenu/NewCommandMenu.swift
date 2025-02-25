import Apps
import Bonzai
import SwiftUI

struct NewCommandButton<Content>: View where Content: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
   Menu {
     ApplicationMenuView()
     FileMenuView()
     KeyboardShortcutMenuView()
     MenuBarMenuView()
     ScriptMenuView()
     ShortcutsMenuView()
     TextMenuView()
     UIElementMenuView()
     URLMenuView()
     WindowMenu()
    } label: {
      content()
    }
  }
}

fileprivate struct ApplicationMenuView: View {
  @ObservedObject var store: ApplicationStore = .shared

  var body: some View {
    Menu {
      Text("System").font(.caption)
      Button(action: { },
             label: { Text("Activate Last Application") })
      Button(action: { },
             label: { Text("Hide All Apps") })

      Text("Applications").font(.caption)
      ForEach(store.applications, id: \.path) { application in
        ApplicationActionMenuView(text: application.bundleName,
                                  app: application)
      }
    } label: {
      Image(systemName: "app")
      Text("Application")
    }
  }
}

fileprivate struct ApplicationActionMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  let text: String
  let app: Application

  var body: some View {
    Menu {
      Text("Actions").font(.caption)
      Button(action: { performUpdate(.open, application: app) },
             label: {
        HStack {
          Image(systemName: "power")
          Text("Open")
        }
      })

      Button(action: { performUpdate(.peek, application: app) },
             label: {
        HStack {
          Image(systemName: "eyes")
          Text("Peek")
        }
      })

      Button(action: { performUpdate(.hide, application: app) },
             label: {
        HStack {
          Image(systemName: "eye.slash")
          Text("Hide")
        }
      })

      Button(action: { performUpdate(.unhide, application: app) },
             label: {
        HStack {
          Image(systemName: "eye")
          Text("Unhide")
        }
      })

      Button(action: { performUpdate(.close, application: app) },
             label: {
        HStack {
          Image(systemName: "poweroff")
          Text("Close")
        }
      })
    } label: {
      Text(text)
    }
  }

  private func performUpdate(_ action: ApplicationCommand.Action, application: Application) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.commands.append(
        .application(.init(action: action, application: application, meta: Command.MetaData(), modifiers: []))
      )
    }
  }
}

fileprivate struct FileMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        OpenPanelController().perform(.selectFile(type: nil, handler: { path in
          print(path)
        }))
      }, label: {
        Text("Browse")
      })
    } label: {
      Image(systemName: "document")
      Text("File")
    }
  }
}

fileprivate struct KeyboardShortcutMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(
            .keyboard(.empty())
          )
        }
      }, label: { Text("New Keyboard Shortcut") })
    } label: {
      Image(systemName: "keyboard")
      Text("Keyboard Shortcut")
    }
  }
}

fileprivate struct MenuBarMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(
            .menuBar(.init(application: nil, tokens: [], meta: Command.MetaData()))
          )
        }

      }, label: { Text("New Menu Bar") })
    } label: {
      Image(systemName: "filemenu.and.selection")
      Text("Menu Bar")
    }
  }
}

fileprivate struct ScriptMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        OpenPanelController().perform(.selectFile(type: "scpt", handler: { path in
          print(path)
        }))
      }, label: { Text("Browse…") })
      Divider()

      Button(action: { performUpdate(.appleScript) }, label: { Text("New Apple Script") })
      #warning("Change this to JXA")
      Button(action: { performUpdate(.appleScript) }, label: { Text("New JXA Script") })
      Button(action: { performUpdate(.shellScript) }, label: { Text("New Shellscript") })
    } label: {
      Image(systemName: "applescript")
      Text("Scripting")
    }
  }

  private func performUpdate(_ script: ScriptCommand.Kind) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.commands.append(
        .script(.init(name: "New Script", kind: script, source: .inline("")))
      )
    }
  }
}

fileprivate struct ShortcutsMenuView: View {
  @EnvironmentObject var shortcutStore: ShortcutStore
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: { }, label: { Text("New Shortcut") })
      Divider()
      ForEach(shortcutStore.shortcuts, id: \.name) { shortcut in
        Button(shortcut.name, action: {
          updater.modifyWorkflow(using: transaction) { workflow in
            workflow.commands.append(
              .shortcut(.init(id: UUID().uuidString, shortcutIdentifier: shortcut.name, name: shortcut.name, isEnabled: true))
            )
          }
        })
      }
    } label: {
      Image(systemName: "s.square")
      Text("Shortcuts")
    }
  }
}

fileprivate struct TextMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(
            .text(.init(.insertText(.init("", mode: .instant, actions: []))))
          )
        }
      }, label: { Text("Insert Text") })
    } label: {
      Image(systemName: "doc.text")
      Text("Text")
    }
  }
}

fileprivate struct UIElementMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(
            .uiElement(.init(predicates: []))
          )
        }
      },
             label: { Text("Capture") })
    } label: {
      Image(systemName: "ellipsis.rectangle")
      Text("UI Element")
    }
  }
}

fileprivate struct URLMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(
            .urlCommand(id: UUID().uuidString, application: nil)
          )
        }
      }, label: { Text("New…") })
      Button(action: {
        // Open Dialog
      }, label: { Text("Enter URL…") })
      Button(action: {
        // Use Clipboard
      }, label: { Text("From Clipboard") })
    } label: {
      Image(systemName: "safari")
      Text("URL")
    }
  }
}

fileprivate struct WindowMenu: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Text("Mission Control").font(.caption)
      Button(action: { performUpdate(.applicationWindows) }, label: { Text("Application Windows") })
      Button(action: { performUpdate(.missionControl) }, label: { Text("All Windows") })
      Button(action: { performUpdate(.showDesktop) }, label: { Text("Show Desktop") })
      Divider()
      WindowFocusMenuView()
      WindowManagementMenuView()
      WindowTilingMenuView()
      Divider()
      Button(action: { }, label: { Text("Minimize All Open Windows") })

    } label: {
      Image(systemName: "macwindow")
      Text("Window")
    }
  }

  private func performUpdate(_ system: SystemCommand.Kind) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.commands.append(
        .systemCommand(.init(name: "", kind: system))
      )
    }
  }
}

fileprivate struct WindowFocusMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      ForEach(WindowFocusCommand.Kind.allCases) { focus in
        Button(action: {
          performUpdate(focus)
        }, label: {
          HStack {
            Image(systemName: focus.symbol)
            Text(focus.displayValue)
          }
        })
      }
    } label: {
      Text("Focus")
    }
  }

  private func performUpdate(_ focus: WindowFocusCommand.Kind) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.commands.append(
        .windowFocus(.init(kind: focus, meta: Command.MetaData()))
      )
    }
  }
}

fileprivate struct WindowManagementMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: { performUpdate(.center) }, label: { Text("Center") })
      Button(action: { performUpdate(.fullscreen(padding: 0)) }, label: { Text("Fullscreen") })
      Button(action: { performUpdate(.move(by: 8, direction: .trailing, padding: 0, constrainedToScreen: false)) }, label: { Text("Move") })
      Button(action: { performUpdate(.decreaseSize(by: 8, direction: .leading, constrainedToScreen: false)) }, label: { Text("Shrink") })
      Button(action: { performUpdate(.increaseSize(by: 8, direction: .trailing, padding: 8, constrainedToScreen: false)) }, label: { Text("Grow") })
      Button(action: { performUpdate(.moveToNextDisplay(mode: .relative)) }, label: { Text("Next Display") })
      Button(action: { performUpdate(.anchor(position: .leading, padding: 8)) }, label: { Text("Anchor & Resize") })
    } label: {
      Text("Management")
    }
  }

  private func performUpdate(_ windowManagement: WindowManagementCommand.Kind) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.commands.append(
        .windowManagement(.init(kind: windowManagement, meta: Command.MetaData(), animationDuration: 0))
      )
    }
  }
}

fileprivate struct WindowTilingMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      ForEach(WindowTiling.allCases) { tiling in
        Button(action: { performUpadte(tiling) }) {
          HStack {
            Image(systemName: tiling.symbol)
            Text(tiling.descriptiveValue)
          }
        }
      }
    } label: {
      Text("Tiling")
    }
  }

  private func performUpadte(_ tiling: WindowTiling) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.commands.append(
        .windowTiling(.init(kind: tiling, meta: Command.MetaData()))
      )
    }
  }
}

#Preview {
  NewCommandButton {
    Image(systemName: "plus")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: 12, height: 16)
      .layoutPriority(-1)
  }
    .buttonStyle { button in
      button.padding = .medium
      button.font = .body
      button.backgroundColor = .systemGreen
    }
    .padding()
    .designTime()
}
