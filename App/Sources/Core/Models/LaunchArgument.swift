import LaunchArguments

enum LaunchArgument: String, LaunchArgumentType {
  case benchmark = "-benchmark"
  case debugEditing = "-debugEditing"
  case injection = "-injection"
  case runningUnitTests = "-running-unit-tests"
  case disableMachPorts = "-disableMachPorts"
}
