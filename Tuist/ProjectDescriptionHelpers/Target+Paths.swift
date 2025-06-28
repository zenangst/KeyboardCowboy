import ProjectDescription

public extension Target {
  static func xcconfig(_ targetName: String) -> String { "Configurations/\(targetName).xcconfig" }

  internal static func sources(_ folder: String) -> SourceFileGlob { "\(folder)/Sources/**" }
  internal static func resources(_ folder: String) -> ResourceFileElements { "\(folder)/Resources/**" }
  internal static func xpcSources() -> SourceFileGlob { "XPC/Sources/**" }
}
