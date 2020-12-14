import SwiftUI
import ModelKit
import ViewKit

struct KeyboardCowboyCommands: Commands {
  let store: Saloon
  let keyInputSubject: KeyInputSubjectWrapper

  @Binding var selectedGroup: ModelKit.Group?
  @Binding var selectedWorkflow: ModelKit.Workflow?

  private var firstResponder: NSResponder? { NSApp.keyWindow?.firstResponder }

  var body: some Commands {
    CommandGroup(replacing: CommandGroupPlacement.pasteboard, addition: {
      Button("Copy") {
        firstResponder?.tryToPerform(#selector(NSText.copy(_:)), with: nil)
      }.keyboardShortcut("c", modifiers: [.command])

      Button("Paste") {
        firstResponder?.tryToPerform(#selector(NSText.paste(_:)), with: nil)
      }.keyboardShortcut("v", modifiers: [.command])

      keyInput(.delete, name: "Delete") {
        firstResponder?.tryToPerform(#selector(NSText.delete(_:)), with: nil)
      }

      Button("Select All") {
        firstResponder?.tryToPerform(#selector(NSText.selectAll(_:)), with: nil)
      }.keyboardShortcut("a", modifiers: [.command])
    })

    CommandMenu("Navigation") {
      keyInput(.upArrow, name: "Select Previous") {
        guard let cgEvent = CGEvent(keyboardEventSource: nil, virtualKey: 126, keyDown: false) else {
          return
        }
        let event = NSEvent.init(cgEvent: cgEvent)
        firstResponder?.tryToPerform(#selector(NSApplication.keyDown(with:)), with: event)
      }

      keyInput(.downArrow, name: "Select Next") {
        guard let cgEvent = CGEvent(keyboardEventSource: nil, virtualKey: 125, keyDown: false) else {
          return
        }
        let event = NSEvent.init(cgEvent: cgEvent)
        firstResponder?.tryToPerform(#selector(NSApplication.keyDown(with:)), with: event)
      }
    }

    CommandGroup(replacing: CommandGroupPlacement.newItem, addition: {
      Button("New Workflow") {
        if let group = selectedGroup {
          store.context.workflow.perform(.create(groupId: group.id))
        }
      }.keyboardShortcut("n", modifiers: [.command])

      Button("New Keyboard shortcut") {
        if store.selectedWorkflow != nil {
          store.context.keyboardsShortcuts.perform(
            .create(ModelKit.KeyboardShortcut.empty(), offset: 999, in: store.context.workflow.state))
        }
      }.keyboardShortcut("k", modifiers: [.command])

      Button("New Group") {
        store.context.groups.perform(.createGroup)
      }.keyboardShortcut("N", modifiers: [.command])
    })

    CommandGroup(after: CommandGroupPlacement.toolbar, addition: {
      Button("Toggle Sidebar") {
        firstResponder?.tryToPerform(
          #selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
      }.keyboardShortcut("S")
    })
  }

  func keyInput(_ key: KeyEquivalent, name: String, modifiers: EventModifiers = [],
                fallbackEvent: @escaping () -> Void) -> some View {
    return keyboardShortcut(key, name: name, sender: keyInputSubject,
                            modifiers: modifiers,
                            fallbackEvent: fallbackEvent)
  }
}
