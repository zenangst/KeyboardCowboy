enum AppEnvironment: String, Hashable, Identifiable {
  var id: String { rawValue }
  case development, production, previews
}
