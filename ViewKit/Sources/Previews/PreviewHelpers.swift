import SwiftUI
import Foundation

// MARK: - Protocols

protocol TestPreviewProvider {
  associatedtype TestPreview: View
  static var testPreview: Self.TestPreview { get }
}

// MARK: - Public extensions

extension View {
  func previewAllColorSchemes() -> some View {
    ColorSchemePreview(view: self)
  }
}

// MARK: - Private types

private struct ColorSchemePreview<T: View>: View {
  let view: T

  var body: some View {
    ForEach(ColorScheme.allCases, id: \.self) { scheme in
      view
        .previewLayout(.sizeThatFits)
        .background(Color(.windowBackgroundColor))
        .colorScheme(scheme)
        .previewDisplayName(scheme.previewName)
    }
  }
}

// MARK: - Private extensions

private extension ColorScheme {
    var previewName: String {
        String(describing: self).capitalized
    }
}
