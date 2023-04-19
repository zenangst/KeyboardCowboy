import SwiftUI

struct ContentImagesView: View {
  let images: [ContentViewModel.ImageModel]

  var body: some View {
    ZStack {
      ForEach(images) { image in
        ContentImageView(image: image)
      }
    }
  }
}
