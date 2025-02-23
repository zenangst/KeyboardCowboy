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
      Text("New Command")
    }
  }
}

fileprivate struct ApplicationMenuView: View {
  var body: some View {
    Menu {
      Text("System").font(.caption)
      Button(action: { }, label: { Text("Activate Last Application") })
      Button(action: { }, label: { Text("Hide All Apps") })

      Text("Applications").font(.caption)
      ForEach(ApplicationStore.shared.applications.lazy) { application in
        ApplicationActionMenuView(text: application.displayName,
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
      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.left.circle")
          Text("Move Focus to Next Window (All Windows)")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.right.circle")
          Text("Move Focus to Previous window (All Windows)") }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.up.circle")
          Text("Move Focus to Next Window")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.down.circle")
          Text("Move Focus to Previous Window")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.up.right.and.arrow.down.left")
          Text("Move Focus to Next Window of Active Application")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.right.circle")
          Text("Move Focus to Previous Window of Active Application")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.left.circle")
          Text("Move Focus to Window Upwards")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.right.to.line.alt")
          Text("Move Focus to Window on Left")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.left.to.line.alt")
          Text("Move Focus to Window on Right")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.forward.circle")
          Text("Move Focus to Window Downwards")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.backward.circle")
          Text("Move Focus to Window in Center")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.up.left.circle")
          Text("Move Focus to Upper Left Quarter")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.up.right.circle")
          Text("Move Focus to Upper Right Quarter")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.down.left.circle")
          Text("Move Focus to Lower Left Quarter")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.down.right.circle")
          Text("Move Focus to Lower Right Quarter")
        }
      })
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
      Button(action: {}, label: {
        HStack {
          Image(systemName: "rectangle.split.2x1")
          Text("Window › Move & Resize › Left")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "rectangle.split.2x1")
          Text("Window › Move & Resize › Right")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "square.split.1x2")
          Text("Window › Move & Resize › Top")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "square.split.1x2")
          Text("Window › Move & Resize › Bottom")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "square.split.bottomrightquarter")
          Text("Window › Move & Resize › Top Left")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "square.split.bottomrightquarter")
          Text("Window › Move & Resize › Top Right")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "square.split.bottomrightquarter")
          Text("Window › Move & Resize › Bottom Left")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "square.split.bottomrightquarter")
          Text("Window › Move & Resize › Bottom Right")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "square.split.diagonal.2x2.fill")
          Text("Window › Center")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "square.fill")
          Text("Window › Fill")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "square.arrowtriangle.4.outward")
          Text("Window › Zoom")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "rectangle.split.2x1.fill")
          Text("Window › Move & Resize › Left & Right")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "rectangle.split.2x1.fill")
          Text("Window › Move & Resize › Right & Left")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "rectangle.split.1x2.fill")
          Text("Window › Move & Resize › Top & Bottom")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "rectangle.split.1x2.fill")
          Text("Window › Move & Resize › Bottom & Top")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "uiwindow.split.2x1")
          Text("Window › Move & Resize › Left & Quarters")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "uiwindow.split.2x1")
          Text("Window › Move & Resize › Right & Quarters")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "uiwindow.split.2x1")
          Text("Window › Move & Resize › Top & Quarters")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "uiwindow.split.2x1")
          Text("Window › Move & Resize › Bottom & Quarters")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "uiwindow.split.2x1")
          Text("Window › Move & Resize › Dynamic & Quarters")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "square.split.2x2")
          Text("Window › Move & Resize › Quarters")
        }
      })

      Button(action: {}, label: {
        HStack {
          Image(systemName: "arrow.uturn.backward.circle.fill")
          Text("Window › Move & Resize › Return to Previous Size")
        }
      })
    } label: {
      Text("Tiling")
    }
  }
}

#Preview {
  NewCommandButton()
    .defaultStyle()
    .padding()
    .designTime()
}
