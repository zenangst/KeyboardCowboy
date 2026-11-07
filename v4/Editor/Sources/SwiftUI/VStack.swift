import SwiftUI

struct VStack<Content>: View where Content: View {
  @Spacing var spacing
  let alignment: HorizontalAlignment
  let content: () -> Content
  let spacingKeyPath: KeyPath<SpacingSpec, Double>?
  let spacingOverride: Double?

  init(@ViewBuilder content: @escaping () -> Content) {
    self.alignment = .leading
    self.content = content
    self.spacingKeyPath = nil
    self.spacingOverride = nil
  }

  init(alignment: HorizontalAlignment = .leading,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.spacingKeyPath = nil
    self.spacingOverride = nil
  }

  init(spacing: Double = 0,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = .leading
    self.content = content
    self.spacingKeyPath = nil
    self.spacingOverride = spacing
  }

  init(spacing: KeyPath<SpacingSpec, Double>,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = .leading
    self.content = content
    self.spacingKeyPath = spacing
    self.spacingOverride = nil
  }

  init(alignment: HorizontalAlignment = .leading,
       spacing: Double = 0,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.spacingKeyPath = nil
    self.spacingOverride = spacing
  }

  init(alignment: HorizontalAlignment = .leading,
       spacing: KeyPath<SpacingSpec, Double>,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.spacingKeyPath = spacing
    self.spacingOverride = nil
  }

  init(alignment: HorizontalAlignment = .leading,
       spacing: Double? = nil,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.spacingKeyPath = nil
    self.spacingOverride = spacing
  }

  var body: some View {
    let resolvedSpacing = spacingOverride ?? spacingKeyPath.map { spacing[keyPath: $0] } ?? spacing.small

    SwiftUI.VStack(alignment: alignment, spacing: resolvedSpacing) {
      content()
    }
  }
}
