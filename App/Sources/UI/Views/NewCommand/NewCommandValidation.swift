enum NewCommandValidation: Identifiable, Equatable {
  var id: String { rawValue }
  case unknown
  case needsValidation
  case invalid(reason: String?)
  case valid

  var rawValue: String {
    switch self {
    case .valid: "valid"
    case .needsValidation: "needsValidation"
    case .unknown: "unknown"
    case .invalid: "invalid"
    }
  }

  var isInvalid: Bool {
    if case .invalid = self {
      true
    } else {
      false
    }
  }

  var isValid: Bool {
    if case .valid = self {
      true
    } else {
      false
    }
  }
}
