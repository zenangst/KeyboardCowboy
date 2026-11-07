import SwiftUI

private struct SurfaceViewModifier<Background: View>: ViewModifier {
  @CornerRadius private var cornerRadius
  @Environment(\.cornerRadius) private var inheritedCornerRadius
  @Environment(\.cornerRadiusValue) private var inheritedCornerRadiusValue
  @Environment(\.inferredPadding) private var inferredPadding
  let background: Background

  func body(content: Content) -> some View {
    let inheritedKeyPath = inferredCornerRadiusKeyPath(from: inheritedCornerRadius)
    let fallbackRadius = cornerRadius[keyPath: inheritedKeyPath]
    let baseRadius = inheritedCornerRadiusValue ?? fallbackRadius
    let resolvedRadius = max(0, baseRadius - Double(inferredPadding))
    let shape = RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous)

    content
      .padding()
      .background { background.clipShape(shape) }
      .environment(\.cornerRadius, inheritedKeyPath)
      .environment(\.cornerRadiusValue, resolvedRadius)
      .compositingGroup()
      .clipShape(shape)
  }
}

extension View {
  func surface() -> some View {
    self
      .modifier(SurfaceViewModifier(background: Color.clear))
  }

  func surface(_ color: Color) -> some View {
    self
      .modifier(SurfaceViewModifier(background: color))
  }

  func surface(_ background: some View) -> some View {
    self
      .modifier(SurfaceViewModifier(background: background))
  }

  func surface(_ style: some ShapeStyle) -> some View {
    self
      .modifier(SurfaceViewModifier(background: Rectangle().fill(style)))
  }
}
