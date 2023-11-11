enum CustomSystemRoutine: String {
  case finder = "com.apple.finder"
  case mail = "com.apple.mail"
  case news = "com.apple.news"
  case notes = "com.apple.Notes"
  case safari = "com.apple.Safari"
  case xcode = "com.apple.dt.Xcode"

  func routine(_ application: UserSpace.Application) -> SystemRoutine {
    switch self {
    case .finder, .mail, .news,
         .notes, .safari, .xcode:
      return OpenApplicationWithNoWindowsSystemRoutine(application: application)
    }
  }
}
