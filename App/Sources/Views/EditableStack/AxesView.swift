import SwiftUI

struct AxesView<Content>: View where Content: View {
  private let axes: EditableAxis
  private let lazy: Bool
  private let spacing: CGFloat?

  @ViewBuilder
  private let content: () -> Content

  internal init(_ axes: EditableAxis,
                lazy: Bool,
                spacing: CGFloat? = nil,
                @ViewBuilder content: @escaping () -> Content) {
    self.axes = axes
    self.spacing = spacing
    self.content = content
    self.lazy = lazy
  }

  @ViewBuilder
  var body: some View {
    switch axes {
    case .vertical:
      if lazy {
        LazyVStack(spacing: spacing, content: content)
      } else {
        VStack(spacing: spacing, content: content)
      }
    case .horizontal:
      if lazy {
        LazyHStack(spacing: spacing, content: content)
      } else {
        HStack(spacing: spacing, content: content)
      }
    }
  }
}
