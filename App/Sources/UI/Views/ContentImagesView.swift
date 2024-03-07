import Inject
import SwiftUI

struct ContentImagesView: View {
  @ObserveInjection var inject
  let images: [ContentViewModel.ImageModel]
  let size: CGFloat
  @State var stacked: Bool = false

  @ViewBuilder
  var body: some View {
    Group {
      if images.isEmpty {
        ZStack(alignment: .center) {
          Image(systemName: "app.dashed")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
        }
        .foregroundColor(.white)
        .compositingGroup()
        .opacity(0.5)
        .frame(width: size, height: size)
      } else {
        ZStack(alignment: .center) {
          ForEach(images) { image in
            ContentImageView(image: image, size: size, stacked: $stacked)
              .drawingGroup()
          }
        }
        .frame(width: size, height: size)
      }
    }
    .enableInjection()
  }
}
