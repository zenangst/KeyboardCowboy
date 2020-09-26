import LaunchArguments

enum LaunchArgument: String, LaunchArgumentType {
  case runningUnitTests = "-running-unit-tests"
  case runWindowless = "-running-without-window"
  case disableKeyboardShortcuts = "-disable-keyboard-shortcuts"
  case demoMode = "-demo-mode"
}
