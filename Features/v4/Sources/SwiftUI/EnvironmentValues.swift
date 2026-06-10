import SwiftUI

extension EnvironmentValues {
  @Entry var brand: any AppBrand = V4Brand()
  @Entry var cornerRadius: KeyPath<CornerRadiusSpec, Double>? = \.medium
  @Entry var cornerRadiusValue: Double?
  @Entry var inferredPadding: CGFloat = 0
  @Entry var spacing: KeyPath<SpacingSpec, Double>?
}
