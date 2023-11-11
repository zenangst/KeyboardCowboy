enum CustomSystemRoutine: String {
  case finder = "com.apple.finder"
  case xcode = "com.apple.dt.Xcode"

  func routine(_ application: UserSpace.Application) -> SystemRoutine {
    switch self {
    case .finder, .xcode:
      return OpenApplicationWithNoWindowsSystemRoutine(application: application)
    }
  }
}
