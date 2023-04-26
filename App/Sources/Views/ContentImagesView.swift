import SwiftUI

struct ContentImagesView: View {
  @ObserveInjection var inject
  let images: [ContentViewModel.ImageModel]

  var body: some View {
    ZStack {
      if images.isEmpty {
        ZStack {
          Image(systemName: "app.dashed")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)

          Image(systemName: "plus")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 8, height: 8)
        }
        .shadow(radius: 1, y: 1)
        .opacity(0.5)
      } else {
        ForEach(images) { image in
          ContentImageView(image: image)
        }
      }
    }
    .debugEdit()
  }
}
