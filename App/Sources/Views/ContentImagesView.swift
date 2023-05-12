import SwiftUI

struct ContentImagesView: View {
  @ObserveInjection var inject
  let images: [ContentViewModel.ImageModel]
  let size: CGFloat
  @State var isHovered: Bool = false

  @ViewBuilder
  var body: some View {
    if images.isEmpty {
      ZStack {
        Image(systemName: "app.dashed")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .fixedSize()
          .frame(width: 24, height: 24)

        Image(systemName: "plus")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .fixedSize()
          .frame(width: 8, height: 8)
      }
      .compositingGroup()
      .shadow(radius: 1, y: 1)
      .opacity(0.5)
    } else {
      ZStack {
        ForEach(images) { image in
          ContentImageView(image: image, size: size)
            .rotationEffect(.degrees(-(isHovered ? -20 * image.offset : 3.75 * image.offset)))
            .offset(.init(width: -(image.offset * (isHovered ? -8 : 1.25)),
                          height: image.offset * (isHovered ? 1.25 : 1.25)))
        }
      }
      .animation(.default, value: isHovered)
      .onHover { newValue in
        isHovered <- newValue
      }
    }
  }
}
