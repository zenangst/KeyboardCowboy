import Apps
import Bonzai
import SwiftUI

struct NewCommandButton: View {
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
      Image(systemName: "plus")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 12, height: 16)
        .layoutPriority(-1)
    }
    .frame(minWidth: 64)
    .fixedSize()
  }
}

fileprivate struct ApplicationMenuView: View {
  @ObservedObject var store: ApplicationStore = .shared

  var body: some View {
    Menu {
      Text("System").font(.caption)
      Button(action: { }, label: { Text("Activate Last Application") })
      Button(action: { }, label: { Text("Hide All Apps") })

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
  let text: String
  let app: Application

  var body: some View {
    Menu {
      Text("Actions").font(.caption)
      Button(action: {}, label: {
        HStack {
          Image(systemName: "power")
          Text("Open")
        }
      })
      Button(action: {}, label: {
        HStack {
          Image(systemName: "eyes")
          Text("Peek")
        }      })
      Button(action: {}, label: {
        HStack {
          Image(systemName: "eye.slash")
          Text("Hide")
        }
      })
      Button(action: {}, label: {
        HStack {
          Image(systemName: "eye")
          Text("Unhide")
        }      })
      Button(action: {}, label: {
        HStack {
          Image(systemName: "poweroff")
          Text("Close")
        }
      })
    } label: {
      Text(text)
    }
  }
}

fileprivate struct FileMenuView: View {
  var body: some View {
    Menu {
      Button(action: { }, label: {
        Text("Browse")
      })
    } label: {
      Image(systemName: "document")
      Text("File")
    }
  }
}

fileprivate struct KeyboardShortcutMenuView: View {
  var body: some View {
    Menu {
      Button(action: { }, label: { Text("New Keyboard Shortcut") })
    } label: {
      Image(systemName: "keyboard")
      Text("Keyboard Shortcut")
    }
  }
}

fileprivate struct MenuBarMenuView: View {
  var body: some View {
    Menu {
      Button(action: { }, label: { Text("New Menu Bar") })
    } label: {
      Image(systemName: "filemenu.and.selection")
      Text("Menu Bar")
    }
  }
}

fileprivate struct ScriptMenuView: View {
  var body: some View {
    Menu {
      Button(action: { }, label: { Text("Browse…") })
      Divider()
      Button(action: { }, label: { Text("New Apple Script") })
      Button(action: { }, label: { Text("New JXA Script") })
      Button(action: { }, label: { Text("New Shellscript") })
    } label: {
      Image(systemName: "applescript")
      Text("Scripting")
    }
  }
}

fileprivate struct ShortcutsMenuView: View {
  @EnvironmentObject var shortcutStore: ShortcutStore

  var body: some View {
    Menu {
      Button(action: { }, label: { Text("New Shortcut") })
        .onAppear {
          Task {
            await shortcutStore.index()
          }
        }
      Divider()
      ForEach(shortcutStore.shortcuts, id: \.name) { shortcut in
        Button(shortcut.name, action: { })
      }
    } label: {
      Image(systemName: "s.square")
      Text("Shortcuts")
    }
  }
}

fileprivate struct TextMenuView: View {
  var body: some View {
    Menu {
      Button(action: { }, label: { Text("Insert Text") })
    } label: {
      Image(systemName: "doc.text")
      Text("Text")
    }
  }
}

fileprivate struct UIElementMenuView: View {
  var body: some View {
    Menu {
      Button(action: { },
             label: { Text("Capture") })
    } label: {
      Image(systemName: "ellipsis.rectangle")
      Text("UI Element")
    }
  }
}

fileprivate struct URLMenuView: View {
  var body: some View {
    Menu {
      Button(action: { }, label: { Text("Enter URL…") })
      Button(action: { }, label: { Text("From Clipboard") })
    } label: {
      Image(systemName: "safari")
      Text("URL")
    }
  }
}

fileprivate struct WindowMenu: View {
  var body: some View {
    Menu {
      Text("Mission Control").font(.caption)
      Button(action: { }, label: { Text("Application Windows") })
      Button(action: { }, label: { Text("All Windows") })
      Button(action: { }, label: { Text("Show Desktop") })
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
}

fileprivate struct WindowFocusMenuView: View {
  var body: some View {
    Menu {
      ForEach(WindowFocusCommand.Kind.allCases) { focus in
        Button(action: {}, label: {
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
}

fileprivate struct WindowManagementMenuView: View {
  var body: some View {
    Menu {
      Button(action: {}, label: { Text("Center") })
      Button(action: {}, label: { Text("Fullscreen") })
      Button(action: {}, label: { Text("Move") })
      Button(action: {}, label: { Text("Shrink") })
      Button(action: {}, label: { Text("Grow") })
      Button(action: {}, label: { Text("Next Display") })
      Button(action: {}, label: { Text("Anchor & Resize") })
    } label: {
      Text("Management")
    }
  }
}

fileprivate struct WindowTilingMenuView: View {
  var body: some View {
    Menu {
      ForEach(WindowTiling.allCases) { tiling in
        Button(action: { }) {
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
}

#Preview {
  NewCommandButton()
    .buttonStyle { button in
      button.padding = .medium
      button.font = .body
      button.backgroundColor = .systemGreen
    }
    .padding()
    .designTime()
}
