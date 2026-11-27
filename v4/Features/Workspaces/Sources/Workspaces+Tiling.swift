public extension Workspaces {
  enum Tiling: String, CaseIterable, Codable, Sendable {
    case arrangeLeftRight, arrangeRightLeft, arrangeTopBottom, arrangeBottomTop
    case arrangeLeftQuarters, arrangeRightQuarters, arrangeTopQuarters, arrangeBottomQuarters
    case arrangeDynamicQuarters, arrangeQuarters, fill, center
  }
}
