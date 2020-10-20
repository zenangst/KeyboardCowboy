import LaunchArguments

enum LaunchArgument: String, LaunchArgumentType {
  case runningUnitTests = "-running-unit-tests"
  case openWindowAtLaunch = "-open-window-at-launch"
  case disableKeyboardShortcuts = "-disable-keyboard-shortcuts"
  case demoMode = "-demo-mode"
}
