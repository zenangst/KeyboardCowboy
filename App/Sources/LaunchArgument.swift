import LaunchArguments

enum LaunchArgument: String, LaunchArgumentType {
  case runningUnitTests = "-running-unit-tests"
  case runWindowless = "-running-without-window"
}
