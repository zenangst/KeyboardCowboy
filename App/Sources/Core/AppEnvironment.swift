enum AppEnvironment: String, Hashable, Identifiable {
  var id: String { rawValue }

  case development
  case production
  case previews
}
