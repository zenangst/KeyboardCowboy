import Apps
import Bonzai
import Inject
import SwiftUI

struct NewCommandButton<Content>: View where Content: View {
  @ObserveInjection var inject
  @ObservedObject var userModePublisher = UserSpace.shared.userModesPublisher
  @ViewBuilder let content: () -> Content

  var body: some View {
   Menu {
     ApplicationMenuView()
     FileMenuView()
     KeyboardMenuView()
     MenuBarMenuView()
     MiscMenuView()
     MouseMenuView()
     ScriptMenuView()
     ShortcutsMenuView()
     TextMenuView()
     UIElementMenuView()
     URLMenuView()
     if !userModePublisher.userModes.isEmpty {
       UserModeMenuView(userModes: userModePublisher.userModes)
     }
     WindowMenu()
    } label: {
      content()
    }
    .enableInjection()
  }
}

fileprivate struct ApplicationMenuView: View {
  @ObservedObject var store: ApplicationStore = .shared
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      MenuLabel("Commands")
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(
            .bundled(.init(.appFocus(.init(bundleIdentifer: "",
                                           hideOtherApps: false, tiling: nil)),
                           meta: Command.MetaData()))
          )
        }
      }, label: {
        HStack {
          Image(systemName: "app.dashed")
          Text("App Focus")
        }
      })

      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(
            .bundled(.init(.appFocus(.init(bundleIdentifer: "",
                                           hideOtherApps: false, tiling: nil)),
                           meta: Command.MetaData()))
          )
        }
      }, label: {
        HStack {
          Image(systemName: "app.gift")
          Text("Workspaces")
        }
      })

      Divider()

      MenuLabel("System")
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(.systemCommand(.init(name: "", kind: .activateLastApplication)))
        }
      }, label: {
        HStack {
          Image(systemName: "appclip")
          Text("Activate Last Application")
        }
      })
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(.systemCommand(.init(name: "", kind: .hideAllApps)))
        }
      }, label: {
        HStack {
          Image(systemName: "eye.slash")
          Text("Hide All Apps")
        }
      })

      Divider()

      MenuLabel("Applications")
      ForEach(store.applications, id: \.path) { application in
        Button(action: { performUpdate(.open, application: application) },
               label: { Text(application.bundleName) })
      }
    } label: {
      Image(systemName: "app")
      Text("Application")
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

fileprivate struct ApplicationActionMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  let text: String
  let app: Application

  var body: some View {
    Menu {
      MenuLabel("Actions")
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
        OpenPanelController().perform(.selectFile(types: [], handler: { path in
          updater.modifyWorkflow(using: transaction, withAnimation: nil) { workflow in
            workflow.commands.append(
              .open(.init(application: nil, path: path, meta: Command.MetaData()))
            )
          }
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

fileprivate struct KeyboardMenuView: View {
  @EnvironmentObject var openWindow: WindowOpener
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        let metaData = Command.MetaData()
        updater.modifyWorkflow(using: transaction, handler: { workflow in
          workflow.commands.append(
            .keyboard(.init(name: "", keyboardShortcuts: [], meta: metaData))
          )
        }, postAction: { workflowId in
            openWindow.openNewCommandWindow(.editCommand(workflowId: workflowId, commandId: metaData.id))
        })
      }, label: { Text("New Keyboard Shortcut") })

      Menu {
        Button(action: {
          updater.modifyWorkflow(using: transaction, handler: { workflow in
            workflow.commands.append(.builtIn(.init(kind: .macro(.record), notification: nil)))
          })
        }, label: { Text("New Macro") })
        Button(action: {
          updater.modifyWorkflow(using: transaction, handler: { workflow in
            workflow.commands.append(.builtIn(.init(kind: .macro(.remove), notification: nil)))
          })
        }, label: { Text("Remove Macro") })
      } label: {
        Text("Macros")
      }

      Divider()

      Button(action: {
        fatalError("NOOP")
      }, label: {
        Text("Change Input Source")
      })

    } label: {
      Image(systemName: "keyboard")
      Text("Keyboard")
    }
  }
}

fileprivate struct MenuBarMenuView: View {
  @EnvironmentObject var openWindow: WindowOpener
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        let metaData = Command.MetaData()
        updater.modifyWorkflow(using: transaction, handler: { workflow in
          workflow.commands.append(
            .menuBar(.init(application: nil, tokens: [], meta: metaData))
          )
        }, postAction: { workflowId in
          openWindow.openNewCommandWindow(.editCommand(workflowId: workflowId, commandId: metaData.id))
        })
      }, label: { Text("New…") })
    } label: {
      Image(systemName: "filemenu.and.selection")
      Text("Menu Bar")
    }
  }
}

fileprivate struct MiscMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(.builtIn(.init(kind: .repeatLastWorkflow, notification: nil)))
        }
      }, label: {
        Text("Repeat Last Workflow")
      })
    } label: {
      HStack {
        Image(systemName: "tree")
        Text("Misc")
      }
    }
  }
}

fileprivate struct MouseMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(.mouse(.empty()))
        }
      }, label: { Text("New…") })
    } label: {
      Image(systemName: "magicmouse")
      Text("Mouse")
    }
  }
}

fileprivate struct ScriptMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        OpenPanelController().perform(.selectFile(types: ["scpt"], handler: { path in
          let metaData = Command.MetaData()
          updater.modifyWorkflow(using: transaction, handler: { workflow in
            workflow.commands.append(
              .script(.init(kind: .appleScript, source: .path(path), meta: metaData))
            )
          })
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
  @EnvironmentObject var openWindow: WindowOpener
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      Button(action: {
        let metaData = Command.MetaData()
        updater.modifyWorkflow(using: transaction, handler: { workflow in
          workflow.commands.append(
            .uiElement(.init(meta: metaData, predicates: []))
          )
        }, postAction: { workflowId in
          openWindow.openNewCommandWindow(.editCommand(workflowId: transaction.workflowID, commandId: metaData.id))
        })
      }, label: { Text("Capture") })
    } label: {
      Image(systemName: "ellipsis.rectangle")
      Text("UI Element")
    }
  }
}

fileprivate struct URLMenuView: View {
  @ObserveInjection var inject
  @EnvironmentObject var windowOpener: WindowOpener
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  @State var input: String = ""

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
        windowOpener.openPrompt {
          URLPrompt(input: $input) { url in
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.commands.append(
                .open(.init(path: url))
              )
            }
          }
        }
      }, label: { Text("Enter URL…") })
      Button(action: {
        // Use Clipboard
      }, label: { Text("From Clipboard") })
    } label: {
      Image(systemName: "safari")
      Text("URL")
    }
    .enableInjection()
  }
}

fileprivate struct URLPrompt: View {
  @ObserveInjection var inject
  @FocusState var focus: Bool
  @EnvironmentObject private var windowEnv: WindowEnvironment
  @Binding var input: String

  var onSave: (String) -> Void

  var body: some View {
    VStack {
      TextField("URL", text: $input)
        .focused($focus)
      Spacer()
      ZenDivider()
      HStack {
        Button(action: { windowEnv.window?.close() }) {
          Text("Discard")
        }
        .keyboardShortcut(.cancelAction)
        Spacer()
        Button(action: {
          windowEnv.window?.close()
          onSave(input)
          input = ""
        }) {
          Text("Save")
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .onAppear {
      focus = true
    }
    .enableInjection()
  }
}

fileprivate struct UserModeMenuView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  private let userModes: [UserMode]

  init(userModes: [UserMode]) {
    self.userModes = userModes
  }

  var body: some View {
    Menu {
      ForEach(userModes) { mode in
        Menu(mode.name) {
          Button(action: { performUpdate(mode, action: .enable) }, label: { Text("Enable") })
          Button(action: { performUpdate(mode, action: .disable) }, label: { Text("Disable") })
          Button(action: { performUpdate(mode, action: .toggle) }, label: { Text("Toggle") })
        }
      }
    } label: {
      HStack {
        Image(systemName: "person.circle")
        Text("User Modes")
      }
    }
  }

  private func performUpdate(_ userMode: UserMode, action: BuiltInCommand.Kind.Action) {
    updater.modifyWorkflow(using: transaction) { workflow in
      workflow.commands.append(
        .builtIn(.init(kind: .userMode(userMode, action), notification: nil))
      )
    }
  }
}

fileprivate struct WindowMenu: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    Menu {
      MenuLabel("Mission Control")
      Button(action: { performUpdate(.applicationWindows) }, label: {
        HStack {
          Image(systemName: "macwindow.on.rectangle")
          Text("Application Windows")
        }
      })
      Button(action: { performUpdate(.missionControl) }, label: {
        HStack {
          Image(systemName: "macwindow")
          Text("All Windows")
        }
      })
      Button(action: { performUpdate(.showDesktop) }, label: {
        HStack {
          Image(systemName: "menubar.dock.rectangle")
          Text("Show Desktop")
        }
      })
      MenuLabel("Commands")
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.append(.builtIn(.init(kind: .windowSwitcher, notification: nil)))
        }
      }, label: {
        HStack {
          Image(systemName: "iphone.app.switcher")
          Text("Window Switcher")
        }
      })
      Button(action: { performUpdate(.minimizeAllOpenWindows) }, label: {
        HStack {
          Image(systemName: "minus.circle")
          Text("Minimize All Open Windows")
        }
      })

      Divider()

      WindowFocusMenuView()
      WindowManagementMenuView()
      WindowTilingMenuView()
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
        Button(action: { performUpdate(focus) },
               label: {
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

fileprivate struct MenuLabel: View {
  private let text: String

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    Text(text)
      .font(.caption)
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
