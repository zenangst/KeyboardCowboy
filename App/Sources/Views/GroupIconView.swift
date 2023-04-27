import SwiftUI

struct GroupIconView: View {
  @Environment(\.controlActiveState) var controlActiveState
  let color: String
  let icon: IconViewModel?
  let symbol: String

  var body: some View {
    Circle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(nsColor: .init(hex: color).blended(withFraction: 1.0, of: NSColor.white)!), location: 0.0),
          .init(color: Color(nsColor: .init(hex: color)), location: 0.015),
          .init(color: Color(nsColor: .init(hex: color).blended(withFraction: 0.1, of: .black)!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
        .opacity(controlActiveState == .key ? 1 : 0.8)
      )
      .overlay(
        Circle()
          .stroke(Color.white, lineWidth: 2)
          .opacity(0.2)
          .mask(
            Circle()
              .fill(
                LinearGradient(stops: [
                  .init(color: .black, location: 0),
                  .init(color: .clear, location: 0.2),
                  .init(color: .clear, location: 1)
                ], startPoint: .top, endPoint: .bottom)
              )
          )
      )
      .grayscale(controlActiveState == .key ? 0 : 0.2)
      .overlay(overlay())
      .compositingGroup()
  }

  @ViewBuilder
  private func overlay() -> some View {
    if let icon = icon {
      IconView(icon: icon, size: .init(width: 20, height: 20))
        .shadow(radius: 2)
    } else {
      Color(.white)
        .contrast(1.2)
        .saturation(1.2)
        .mask {
          Image(systemName: symbol)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 14, height: 14)
        }
        .shadow(color: Color(nsColor: .textColor).opacity(0.1), radius: 0, y: -0.5)
        .shadow(color: Color(nsColor: .textBackgroundColor).opacity(0.25), radius: 0, y: 0.5)
    }
  }
}

struct GroupIconView_Previews: PreviewProvider {
  static var previews: some View {
    GroupIconView(color: "#f0f0", icon: nil, symbol: "folder")
  }
}
