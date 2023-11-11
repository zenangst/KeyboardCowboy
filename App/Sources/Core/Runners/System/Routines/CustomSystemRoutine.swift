enum CustomSystemRoutine: String {
  case finder = "com.apple.finder"

  func routine(_ application: UserSpace.Application) -> SystemRoutine {
    switch self {
    case .finder:
      return FinderSystemRoutine(application: application)
    }
  }
}
