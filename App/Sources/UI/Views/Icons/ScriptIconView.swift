import SwiftUI

struct ScriptIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(Color(.black))
      .overlay { iconOverlay() }
      .overlay { iconBorder(size) }
      .overlay(alignment: .topLeading) {
        HStack(spacing: 0) {
          Text(">")
            .font(Font.system(size: size * 0.375, weight: .regular, design: .rounded))
            .padding(.top, size * 0.05)
            .padding(.leading, size * 0.1)
            .foregroundColor(
              Color(nsColor: .controlAccentColor.withSystemEffect(.rollover))
            )
            .shadow(color: .white, radius: 15, y: 5)
          Text("_")
            .font(Font.system(size: size * 0.375, weight: .regular, design: .rounded))
            .padding(.top, size * 0.05)
            .foregroundColor(
              Color(nsColor: .controlAccentColor.withSystemEffect(.deepPressed))
            )
            .shadow(color: Color(.controlAccentColor), radius: 10, y: 2)
        }
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
