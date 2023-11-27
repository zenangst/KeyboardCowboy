enum CustomMouseRoutine: String {
  case xcode = "com.apple.dt.Xcode"

  func routine(roleDescription: KnownAccessibilityRoleDescription) -> MouseRoutine? {
    switch self {
    case .xcode: XcodeMouseRoutine(roleDescription)
    }
  }
}
