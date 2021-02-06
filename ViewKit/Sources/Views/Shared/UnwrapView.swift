import SwiftUI

/// Credit to Swift by Sundell (John Sundell)
/// https://www.swiftbysundell.com/tips/optional-swiftui-views/
public struct Unwrap<Value, Content: View>: View {
  public typealias ContentProvider = (Value) -> Content
  private let value: Value?
  private let contentProvider: ContentProvider

  public init(_ value: Value?, @ViewBuilder contentProvider: @escaping ContentProvider) {
    self.value = value
    self.contentProvider = contentProvider
  }

  public var body: some View {
    value.map(contentProvider)
  }
}
