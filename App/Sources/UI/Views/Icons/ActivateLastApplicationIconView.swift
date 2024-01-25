import SwiftUI

struct ActivateLastApplicationIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(Color(nsColor: .systemPink))
      .overlay {
        AngularGradient(stops: [
          .init(color: Color.clear, location: 0.0),
          .init(color: Color.white.opacity(0.2), location: 0.2),
          .init(color: Color.clear, location: 1.0),
        ], center: .bottomLeading)

        LinearGradient(stops: [
          .init(color: Color.white.opacity(0.2), location: 0),
          .init(color: Color.clear, location: 0.3),
        ], startPoint: .top, endPoint: .bottom)

        LinearGradient(stops: [
          .init(color: Color.clear, location: 0.8),
          .init(color: Color(.windowBackgroundColor).opacity(0.3), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      }
      .overlay(alignment: .center) {
        Image(systemName: "app")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: size * 0.7)
      }
      .overlay(alignment: .center) {
        Image(systemName: "arrowshape.turn.up.backward.fill")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: size * 0.35)
          .offset(x: -size * 0.015, y: -size * 0.015)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    ActivateLastApplicationIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      ActivateLastApplicationIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        ActivateLastApplicationIconView(size: 64)
        ActivateLastApplicationIconView(size: 32)
        ActivateLastApplicationIconView(size: 16)
      }
    }
  }
  .padding()
}

