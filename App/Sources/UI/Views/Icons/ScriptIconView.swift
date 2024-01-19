import SwiftUI

struct ScriptIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(Color(.black))
      .overlay {
        AngularGradient(stops: [
          .init(color: Color.clear, location: 0.0),
          .init(color: Color(.controlAccentColor).opacity(0.5), location: 0.2),
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
      .overlay(alignment: .topLeading) {
        Text(">_")
          .font(Font.system(size: size * 0.375, design: .monospaced))
          .padding(.top, size * 0.05)
          .padding(.leading, size * 0.1)
          .foregroundColor(
            Color(nsColor: .controlAccentColor.withSystemEffect(.deepPressed))
          )
          .shadow(color: .white, radius: 15, y: 5)
      }
      .overlay {
        RoundedRectangle(cornerRadius: size * 0.1_25)
          .stroke(        LinearGradient(stops: [
            .init(color: Color(.windowBackgroundColor), location: 0.0),
            .init(color: Color(.systemGray), location: 0.2),
            .init(color: Color(.windowBackgroundColor), location: 1.0),
          ], startPoint: .topLeading, endPoint: .bottomTrailing)
                          , lineWidth: size * 0.0_3)

        RoundedRectangle(cornerRadius: size * 0.105)
          .stroke(        LinearGradient(stops: [
            .init(color: Color(.windowBackgroundColor), location: 0.0),
            .init(color: Color(.systemGray), location: 0.2),
            .init(color: Color(.windowBackgroundColor), location: 1.0),
          ], startPoint: .bottomTrailing, endPoint: .topLeading)
                          , lineWidth: size * 0.0_175)
          .padding(size * 0.0_24)

      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    ScriptIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      ScriptIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        ScriptIconView(size: 64)
        ScriptIconView(size: 32)
        ScriptIconView(size: 16)
      }
    }
  }
  .padding()
}
