import Foundation

enum AppFocus: Hashable {
  case groups
  case workflows
  case detail(Detail)
  case search

  enum Detail: Hashable {
    case name
    case addAppTrigger
    case addKeyboardTrigger
    case applicationTriggers
    case applicationTrigger(ApplicationTrigger.ID)
    case keyboardShortcuts
    case keyboardShortcut(KeyShortcut.ID)
    case addCommand
    case commands
    case command(Command.ID)
    case commandShortcut(KeyShortcut.ID)
  }
}
