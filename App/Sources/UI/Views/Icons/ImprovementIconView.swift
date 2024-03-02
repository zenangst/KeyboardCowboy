import SwiftUI

struct ImprovementIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(nsColor: .textBackgroundColor), location: 0.25),
          .init(color: Color(nsColor: .textBackgroundColor.blended(withFraction: 0.1, of: .black)!), location: 1),
        ], startPoint: .top, endPoint: .bottom)
      )
      .overlay { iconOverlay() }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemYellow), location: 0.25),
          .init(color: Color.orange, location: 0.75),
          .init(color: Color(.systemRed), location: 1)
        ], startPoint: .top, endPoint: .bottom)
        .mask {
          VStack(alignment: .leading, spacing: 0) {
              Text("LEVEL")
                .font(Font.system(size: size * 0.25, weight: .heavy, design: .rounded))
              HStack(spacing: 0) {
                Text("UP")
                  .font(Font.system(size: size * 0.3, weight: .heavy, design: .rounded))
                Image(systemName: "arrowshape.turn.up.left.fill")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .rotationEffect(.degrees(90))
                  .frame(width: size * 0.35)
            }
          }
        }
        .padding(size * 0.05)
      }
      .iconShape(size)
      .frame(width: size, height: size)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    ImprovementIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      ImprovementIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        ImprovementIconView(size: 64)
        ImprovementIconView(size: 32)
        ImprovementIconView(size: 16)
      }
    }
  }
  .padding()
}

