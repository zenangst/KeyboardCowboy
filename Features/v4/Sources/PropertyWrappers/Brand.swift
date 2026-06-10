import SwiftUI

@propertyWrapper
struct Brand: DynamicProperty {
  @Environment(\.brand) private var brand

  init() {}

  var wrappedValue: any AppBrand { brand }
}
