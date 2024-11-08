import Bonzai
import SwiftUI

struct GroupIconView: View {
  @Environment(\.controlActiveState) var controlActiveState
  let color: String
  let icon: Icon?
  let symbol: String

  var body: some View {
    Circle()
      .fill(Color(.init(hex: color)))
      .grayscale(controlActiveState == .key ? 0 : 0.2)
      .opacity(controlActiveState == .key ? 1 : 0.8)
      .overlay(GroupIconOverlayView(icon: icon, symbol: symbol))
  }
}

private struct GroupIconOverlayView: View {
  let icon: Icon?
  let symbol: String

  var body: some View {
    ZStack {
      IconView(icon: icon, size: .init(width: 20, height: 20))
        .opacity(icon != nil ? 1 : 0)
      Color(.white)
        .contrast(1.2)
        .saturation(1.2)
        .mask {
          if !symbol.isEmpty {
            Image(systemName: symbol)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 14, height: 14)
              .opacity(!symbol.isEmpty ?  1 : 0)
          }
        }
        .compositingGroup()
        .shadow(color: Color(nsColor: .textColor).opacity(0.1), radius: 0, y: -0.5)
        .shadow(color: Color(nsColor: .textBackgroundColor).opacity(0.25), radius: 0, y: 0.5)
        .opacity(icon == nil ? 1 : 0)
    }
  }
}

struct GroupIconView_Previews: PreviewProvider {
  static var previews: some View {
    GroupIconView(color: "#f0f0", icon: nil, symbol: "folder")
  }
}
