import SwiftUI

struct WorkflowImages: View {
  let images: [GroupDetailViewModel.ImageModel]
  let size: CGFloat
  @State var stacked: Bool = false

  @ViewBuilder
  var body: some View {
    ZStack(alignment: .center) {
      Image(systemName: "app.dashed")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 24, height: 24)
        .foregroundColor(.white)
        .compositingGroup()
        .opacity(images.isEmpty ? 0.5 : 0)

      ForEach(images) { image in
        WorkflowImage(image: image, size: size, stacked: $stacked)
      }
    }
    .frame(width: size, height: size)
  }
}
