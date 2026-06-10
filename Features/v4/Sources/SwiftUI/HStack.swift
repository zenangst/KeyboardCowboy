import SwiftUI

struct HStack<Content>: View where Content: View {
  @Spacing var spacing
  let alignment: VerticalAlignment
  let content: () -> Content
  let spacingKeyPath: KeyPath<SpacingSpec, Double>?
  let spacingOverride: Double?

  init(@ViewBuilder content: @escaping () -> Content) {
    self.alignment = .center
    self.content = content
    self.spacingKeyPath = nil
    self.spacingOverride = nil
  }

  init(alignment: VerticalAlignment = .center,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.spacingKeyPath = nil
    self.spacingOverride = nil
  }

  init(spacing: Double = 0,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = .center
    self.content = content
    self.spacingKeyPath = nil
    self.spacingOverride = spacing
  }

  init(spacing: KeyPath<SpacingSpec, Double>,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = .center
    self.content = content
    self.spacingKeyPath = spacing
    self.spacingOverride = nil
  }

  init(alignment: VerticalAlignment = .center,
       spacing: Double = 0,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.spacingKeyPath = nil
    self.spacingOverride = spacing
  }

  init(alignment: VerticalAlignment = .center,
       spacing: KeyPath<SpacingSpec, Double>,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.spacingKeyPath = spacing
    self.spacingOverride = nil
  }

  init(alignment: VerticalAlignment = .center,
       spacing: Double? = nil,
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.spacingKeyPath = nil
    self.spacingOverride = spacing
  }

  var body: some View {
    let resolvedSpacing = spacingOverride ?? spacingKeyPath.map { spacing[keyPath: $0] } ?? spacing.medium

    SwiftUI.HStack(alignment: alignment, spacing: resolvedSpacing) {
      content()
    }
  }
}
