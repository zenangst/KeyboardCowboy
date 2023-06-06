import SwiftUI

struct AppLoadingView: View {
  private let namespace: Namespace.ID
  @State var done: Bool = false

  init(namespace: Namespace.ID) {
    self.namespace = namespace
  }

  var body: some View {
    VStack {
      KeyboardCowboyAsset.applicationIcon.swiftUIImage
        .resizable()
        .frame(width: 64, height: 64)
        .matchedGeometryEffect(id: "initial-item", in: namespace)
      Text("Loading ...")
    }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(SplashView(done: $done))
  }
}

struct AppLoadingView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    AppLoadingView(namespace: namespace)
  }
}
