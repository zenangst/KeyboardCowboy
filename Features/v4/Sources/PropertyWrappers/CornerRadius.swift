import SwiftUI

@propertyWrapper
struct CornerRadius: DynamicProperty {
  @Environment(\.brand) private var brand

  init() {}

  var wrappedValue: CornerRadiusSpec { brand.cornerRadius }
}
