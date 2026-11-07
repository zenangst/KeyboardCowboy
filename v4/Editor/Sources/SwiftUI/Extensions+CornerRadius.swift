import SwiftUI

func inferredCornerRadiusKeyPath(
  from keyPath: KeyPath<CornerRadiusSpec, Double>?,
) -> KeyPath<CornerRadiusSpec, Double> {
  switch keyPath {
  case \.extraLarge: \.large
  case \.large: \.medium
  case \.medium: \.small
  case \.small, \.none: \.small
  case nil: \.large
  default: \.medium
  }
}

private struct CornerRadiusModifier: ViewModifier {
  @CornerRadius private var cornerRadius
  let keyPath: KeyPath<CornerRadiusSpec, Double>

  func body(content: Content) -> some View {
    let radius = cornerRadius[keyPath: keyPath]

    content
      .environment(\.cornerRadius, keyPath)
      .environment(\.cornerRadiusValue, radius)
      .compositingGroup()
      .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
  }
}

private struct InheritedCornerRadiusModifier: ViewModifier {
  @CornerRadius private var cornerRadius
  @Environment(\.cornerRadius) private var inheritedCornerRadius
  @Environment(\.cornerRadiusValue) private var inheritedCornerRadiusValue
  @Environment(\.inferredPadding) private var inferredPadding

  func body(content: Content) -> some View {
    let inheritedKeyPath = inferredCornerRadiusKeyPath(from: inheritedCornerRadius)
    let fallbackRadius = cornerRadius[keyPath: inheritedKeyPath]
    let baseRadius = inheritedCornerRadiusValue ?? fallbackRadius
    let resolvedRadius = max(0, baseRadius - Double(inferredPadding))

    content
      .environment(\.cornerRadius, inheritedKeyPath)
      .environment(\.cornerRadiusValue, resolvedRadius)
      .compositingGroup()
      .clipShape(RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous))
  }
}

extension View {
  func cornerRadius() -> some View {
    self
      .modifier(InheritedCornerRadiusModifier())
  }

  func cornerRadius(_ keyPath: KeyPath<CornerRadiusSpec, Double>) -> some View {
    self
      .modifier(CornerRadiusModifier(keyPath: keyPath))
  }
}
