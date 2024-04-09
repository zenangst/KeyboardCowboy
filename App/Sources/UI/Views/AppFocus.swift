import Foundation

enum AppFocus: Hashable {
  case groups
  case workflows
  case detail(Detail)
  case search

  enum Detail: Hashable {
    case addAppTrigger
    case addCommand
    case addKeyboardTrigger
    case addSnippetTrigger
    case applicationTrigger(ApplicationTrigger.ID)
    case applicationTriggers
    case command(Command.ID)
    case commandShortcut(KeyShortcut.ID)
    case commands
    case keyboardShortcut(KeyShortcut.ID)
    case keyboardShortcuts
    case name
    case snippet
  }
}
