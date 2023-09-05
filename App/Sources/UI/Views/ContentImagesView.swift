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
          .frame(width: 24, height: 24)
        Image(systemName: "plus")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .fixedSize()
          .shadow(radius: 1, y: 1)
      }
      .foregroundColor(.white)
      .compositingGroup()
      .opacity(0.5)
      .frame(width: size, height: size)
    } else {
      ZStack {
        if images.count == 1 {
          ForEach(images.lazy) { image in
            ContentImageView(image: image, size: size - 2)
          }
        } else if images.count > 1 {
          ForEach(images.lazy) { image in
            ContentImageView(image: image, size: size - 2)
              .rotationEffect(.degrees(-(isHovered ? -20 * image.offset : 3.75 * image.offset)))
              .offset(.init(width: -(image.offset * (isHovered ? -8 : 1.25)),
                            height: image.offset * (isHovered ? 1.25 : 1.25)))
          }
        }
      }
      .animation(.default, value: isHovered)
      .onHover { newValue in
        isHovered <- newValue
      }
    }
  }
}
