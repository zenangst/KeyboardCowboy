import LaunchArguments

let launchArguments = LaunchArgumentsController<LaunchArgument>()

enum LaunchArgument: String, LaunchArgumentType {
  // Used to avoid running the application when running unit tests
  case runningUnitTests = "-running-unit-tests"
  // Determines if the main window should open at launch.
  // Encourage during development to ease the development process
  // while testing changes.
  case openWindowAtLaunch = "-open-window-at-launch"
  // Disable setting up keyboard shortcut during development.
  case disableKeyboardShortcuts = "-disable-keyboard-shortcuts"
  // When enabled, the application will use the bundled JSON file
  // to display information.
  case demoMode = "-demo-mode"
  // Will print information to the console while running the
  // application. Great for debugging.
  case debug = "-debug"
}
