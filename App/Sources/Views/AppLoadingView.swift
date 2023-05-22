import SwiftUI

struct AppLoadingView: View {
  @State var done: Bool = false

  var body: some View {
    VStack {
      KeyboardCowboyAsset.applicationIcon.swiftUIImage
        .resizable()
        .frame(width: 64, height: 64)
      Text("Loading ...")
    }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(SplashView(done: $done))
  }
}

struct AppLoadingView_Previews: PreviewProvider {
  static var previews: some View {
    AppLoadingView()
  }
}
