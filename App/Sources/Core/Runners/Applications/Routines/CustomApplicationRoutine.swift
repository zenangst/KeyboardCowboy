enum CustomApplicationRoutine: String {
  case keyboardCowboy = "com.zenangst.Keyboard-Cowboy"

  func routine() -> ApplicationRoutine {
    switch self {
    case .keyboardCowboy:
      return KeyboardCowboyApplicationRoutine()
    }
  }
}
