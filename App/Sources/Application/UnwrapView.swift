import SwiftUI
import ViewKit

/// Credit to Swift by Sundell (John Sundell)
/// https://www.swiftbysundell.com/tips/optional-swiftui-views/
struct Unwrap<Value, Content: View>: View {
  typealias ContentProvider = (Value) -> Content
  private let value: Value?
  private let contentProvider: ContentProvider

  init(_ value: Value?, @ViewBuilder content: @escaping ContentProvider) {
    self.value = value
    self.contentProvider = content
  }

  var body: some View {
    value.map(contentProvider)
  }
}
