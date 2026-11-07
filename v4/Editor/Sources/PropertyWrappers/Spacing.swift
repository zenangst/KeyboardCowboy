import SwiftUI

@propertyWrapper
struct Spacing: DynamicProperty {
  @Environment(\.brand) private var brand

  init() {}

  var wrappedValue: SpacingSpec { brand.spacing }
}
