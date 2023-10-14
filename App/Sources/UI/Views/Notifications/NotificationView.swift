import SwiftUI

struct NotificationView<Content: View>: View {
  let alignment: Alignment
  @ViewBuilder
  let content: () -> Content

  init(_ alignment: Alignment, @ViewBuilder content: @escaping () -> Content) {
    self.alignment = alignment
    self.content = content
  }

  var body: some View {
    HStack {
      AlignmentSpacer(alignment, validAlignments: .topTrailing, .trailing, .bottomTrailing)
      VStack(alignment: horizontalAlignment) {
        AlignmentSpacer(alignment, validAlignments: .bottom, .bottomLeading, .bottomTrailing)
        content()
          .frame(alignment: alignment)
        AlignmentSpacer(alignment, validAlignments: .top, .topLeading, .topTrailing)
      }
      AlignmentSpacer(alignment, validAlignments: .topLeading, .leading, .bottomLeading)
    }
  }

  private var horizontalAlignment: HorizontalAlignment {
    switch alignment {
    case .topLeading, .leading, .bottomLeading: .leading
    case .topTrailing, .trailing, .bottomLeading: .trailing
    default: .center
    }
  }
}

struct AlignmentSpacer: View {
  let alignment: Alignment
  let validAlignments: [Alignment]

  init(_ alignment: Alignment, validAlignments: Alignment...) {
    self.alignment = alignment
    self.validAlignments = validAlignments
  }

  var body: some View {
    if validAlignments.contains(alignment) {
      Spacer()
    }
  }
}

struct NotificationView_Previews: PreviewProvider {
  static var previews: some View {
    NotificationView(.bottomTrailing) {
      Text("ohai!")
    }
    .frame(width: 480, height: 320)
  }
}
