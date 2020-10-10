import LaunchArguments

enum LaunchArgument: String, LaunchArgumentType {
  case runningUnitTests = "-running-unit-tests"
  case openWindowAtLaunch = "-open-widnow-at-launch"
  case disableKeyboardShortcuts = "-disable-keyboard-shortcuts"
  case demoMode = "-demo-mode"
}
