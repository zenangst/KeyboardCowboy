public extension Workspaces {
  enum Step: Equatable, Sendable {
    case application(ApplicationStep)
    case tiling(Tiling)
    case hideAllApps(name: String, delayMilliseconds: Int?)
  }
}
