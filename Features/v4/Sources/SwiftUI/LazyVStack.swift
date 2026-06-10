import SwiftUI

struct LazyVStack<Content>: View where Content: View {
  @Spacing var spacing
  let alignment: HorizontalAlignment
  let content: () -> Content
  let pinnedViews: PinnedScrollableViews
  let spacingKeyPath: KeyPath<SpacingSpec, Double>?
  let spacingOverride: Double?

  init(@ViewBuilder content: @escaping () -> Content) {
    self.alignment = .leading
    self.content = content
    self.pinnedViews = []
    self.spacingKeyPath = nil
    self.spacingOverride = nil
  }

  init(alignment: HorizontalAlignment = .leading,
       pinnedViews: PinnedScrollableViews = [],
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.pinnedViews = pinnedViews
    self.spacingKeyPath = nil
    self.spacingOverride = nil
  }

  init(spacing: Double = 0,
       pinnedViews: PinnedScrollableViews = [],
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = .leading
    self.content = content
    self.pinnedViews = pinnedViews
    self.spacingKeyPath = nil
    self.spacingOverride = spacing
  }

  init(spacing: KeyPath<SpacingSpec, Double>,
       pinnedViews: PinnedScrollableViews = [],
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = .leading
    self.content = content
    self.pinnedViews = pinnedViews
    self.spacingKeyPath = spacing
    self.spacingOverride = nil
  }

  init(alignment: HorizontalAlignment = .leading,
       spacing: Double = 0,
       pinnedViews: PinnedScrollableViews = [],
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.pinnedViews = pinnedViews
    self.spacingKeyPath = nil
    self.spacingOverride = spacing
  }

  init(alignment: HorizontalAlignment = .leading,
       spacing: KeyPath<SpacingSpec, Double>,
       pinnedViews: PinnedScrollableViews = [],
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.pinnedViews = pinnedViews
    self.spacingKeyPath = spacing
    self.spacingOverride = nil
  }

  init(alignment: HorizontalAlignment = .leading,
       spacing: Double? = nil,
       pinnedViews: PinnedScrollableViews = [],
       @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
    self.pinnedViews = pinnedViews
    self.spacingKeyPath = nil
    self.spacingOverride = spacing
  }

  var body: some View {
    let resolvedSpacing = spacingOverride ?? spacingKeyPath.map { spacing[keyPath: $0] } ?? spacing.medium

    SwiftUI.LazyVStack(
      alignment: alignment,
      spacing: resolvedSpacing,
      pinnedViews: pinnedViews,
    ) {
      content()
    }
  }
}
