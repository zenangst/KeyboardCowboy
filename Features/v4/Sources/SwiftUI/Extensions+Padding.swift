import SwiftUI

private struct PaddingViewModifier: ViewModifier {
  @Spacing private var spacing
  @Environment(\.inferredPadding) private var inferredPadding
  @State private var inferredContext = InferredLayoutContext.empty
  let edges: Edge.Set
  let keyPath: KeyPath<SpacingSpec, Double>

  func body(content: Content) -> some View {
    let length = spacing[keyPath: keyPath]
    let totalInset = inferredPadding + length
    let context = InferredLayoutContext(spacing: keyPath, inset: totalInset)

    content
      .onPreferenceChange(InferredLayoutContextPreferenceKey.self) { inferredContext = $0 }
      .padding(edges, length)
      .environment(\.spacing, keyPath)
      .environment(\.inferredPadding, totalInset)
      .preference(key: InferredLayoutContextPreferenceKey.self, value: context)
  }
}

private struct InheritedPaddingViewModifier: ViewModifier {
  @Spacing private var spacing
  @Environment(\.spacing) private var inheritedSpacing
  @Environment(\.inferredPadding) private var inferredPadding
  @State private var inferredContext = InferredLayoutContext.empty
  let edges: Edge.Set

  func body(content: Content) -> some View {
    let keyPath = inferredContext.spacing ?? inheritedSpacing ?? \.medium
    let length = spacing[keyPath: keyPath]
    let totalInset = inferredPadding + length
    let context = InferredLayoutContext(spacing: keyPath, inset: totalInset)

    content
      .onPreferenceChange(InferredLayoutContextPreferenceKey.self) { inferredContext = $0 }
      .padding(edges, length)
      .environment(\.spacing, keyPath)
      .environment(\.inferredPadding, totalInset)
      .preference(key: InferredLayoutContextPreferenceKey.self, value: context)
  }
}

extension View {
  func padding() -> some View {
    self
      .modifier(InheritedPaddingViewModifier(edges: .all))
  }

  func padding(_ edges: Edge.Set = .all) -> some View {
    self
      .modifier(InheritedPaddingViewModifier(edges: edges))
  }

  func padding(_ keyPath: KeyPath<SpacingSpec, Double>) -> some View {
    self
      .modifier(PaddingViewModifier(edges: .all, keyPath: keyPath))
  }

  func padding(_ edges: Edge.Set = .all, _ keyPath: KeyPath<SpacingSpec, Double>) -> some View {
    self
      .modifier(PaddingViewModifier(edges: edges, keyPath: keyPath))
  }
}
