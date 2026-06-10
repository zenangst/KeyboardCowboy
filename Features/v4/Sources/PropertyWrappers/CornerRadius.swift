import SwiftUI

@propertyWrapper
struct CornerRadius: DynamicProperty {
  @Environment(\.brand) private var brand

  public init() {}

  public var wrappedValue: CornerRadiusSpec { brand.cornerRadius }
}
