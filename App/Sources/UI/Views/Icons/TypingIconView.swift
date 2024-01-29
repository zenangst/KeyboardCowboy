import Bonzai
import SwiftUI

struct TypingIconView: View {
  let text = """
Here’s to the crazy ones. The misfits. The rebels. The troublemakers. The round pegs in the square holes. The ones who see things differently.
""".split(separator: " ").map(String.init)
  let highlights: [Int] = [3,4, 6, 8, 10, 22, 23]
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(.white)
      .overlay(alignment: .leading) {
        Rectangle()
          .fill(Color(.systemRed).opacity(0.25))
          .frame(width: size * 0.01)
          .padding(.leading, size * 0.05)
      }
      .overlay(alignment: .topLeading) {
        VStack(spacing: size * 0.0_76) {
          Rectangle()
            .fill(Color(.black).opacity(0.25))
            .frame(height: 1)

          Rectangle()
            .fill(Color(.black).opacity(0.25))
            .frame(height: 1)

          Rectangle()
            .fill(Color(.black).opacity(0.25))
            .frame(height: 1)

          Rectangle()
            .fill(Color(.black).opacity(0.25))
            .frame(height: 1)

          Rectangle()
            .fill(Color(.black).opacity(0.25))
            .frame(height: 1)

          Rectangle()
            .fill(Color(.black).opacity(0.25))
            .frame(height: 1)

          Rectangle()
            .fill(Color(.black).opacity(0.25))
            .frame(height: 1)
        }
        .padding(.top, size * 0.11)
      }
      .overlay(alignment: .center) {
        FlowLayout(
          itemSpacing: size * 0.0_16,
          padding: size * 0.0_2,
          minSize: .init(width: size, height: size)
        ) {
          ForEach(Array(zip(text.indices, text)), id: \.0) { index, element in
            Text(element)
              .foregroundStyle(Color.black)
              .font(.system(size: size * 0.0_67))
              .fontDesign(.rounded)
              .overlay {
                RoundedRectangle(cornerRadius: size * 0.0_25)
                  .fill(color(for: index, total: text.count))
                  .padding(.vertical, size * 0.0_11)
              }
              .compositingGroup()
              .padding(.top, 0.6)
          }
        }
        .padding(.leading, size * 0.05)
      }
      .overlay(alignment: .bottomTrailing) {
        Image(systemName: "character.cursor.ibeam")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundStyle(
            .black.opacity(0.25),
            .white
          )
          .fontWeight(.heavy)
          .frame(width: size * 0.3)
          .padding(size * 0.1)
          .background(
            LinearGradient(stops: [
              .init(color: Color(nsColor: .controlAccentColor.withSystemEffect(.rollover)), location: 0),
              .init(color: Color(nsColor: .controlAccentColor), location: 0.8),
              .init(color: Color(nsColor: .controlAccentColor.withSystemEffect(.disabled)), location: 1.0),
            ], startPoint: .top, endPoint: .bottomTrailing)
              .cornerRadius(size * 0.125)
          )
          .compositingGroup()
          .shadow(radius: 3)
          .padding([.bottom], size * 0.0_55)
          .padding([.trailing], size * 0.055)
          .shadow(radius: 2, x: 5, y: 5)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }

  private func color(for index: Int, total: Int) -> Color {
    highlights.contains(index)
    ? Color(.systemYellow).opacity(0.4) // Color(nsColor: .controlAccentColor.withSystemEffect(.disabled))
    : Color.clear
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    TypingIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      TypingIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        TypingIconView(size: 64)
        TypingIconView(size: 32)
        TypingIconView(size: 16)
      }
    }
  }
  .padding()

}
