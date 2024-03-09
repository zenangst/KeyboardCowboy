import Bonzai
import SwiftUI

struct TypingIconView: View {
  let contents: [TextContent] = [
    TextContent(text: "Here’s to the crazy ones.", highlightedWords: [3, 4]),
    TextContent(text: "The misfits. The rebels.", highlightedWords: [1, 3]),
    TextContent(text: "The troublemakers.", highlightedWords: [1]),
    TextContent(text: "The round pegs in the", highlightedWords: [2]),
    TextContent(text: "square holes.", highlightedWords: [1, 2]),
    TextContent(text: "The ones", highlightedWords: [0]),
    TextContent(text: "who see", highlightedWords: [0]),
    TextContent(text: "things", highlightedWords: []),
    TextContent(text: "differently.", highlightedWords: [0]),
  ]
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(.white)
      .overlay { iconOverlay().opacity(0.5) }
      .overlay { iconBorder(size) }
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

          Rectangle()
            .fill(Color(.black).opacity(0.25))
            .frame(height: 1)

          Rectangle()
            .fill(Color(.black).opacity(0.25))
            .frame(height: 1)
        }
        .padding(.top, size * 0.11)
      }
      .overlay(alignment: .topLeading) {
        VStack(alignment: .leading, spacing: size * 0.005) {
          ForEach(contents) { content in
            HStack(spacing: size * 0.0_1) {
              ForEach(content.words) { word in
                Text(word.content)
                  .overlay {
                    RoundedRectangle(cornerRadius: size * 0.0_25)
                      .fill(color(for: word.offset, highlights: content.highlightedWords))
                      .padding(.vertical, size * 0.0_11)
                  }
              }
            }
            .allowsTightening(true)
            .foregroundStyle(Color.black)
            .font(.system(size: size * 0.0_67))
            .fontDesign(.rounded)
            .compositingGroup()
          }
        }
        .padding([.top, .leading], size * 0.11)
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

  private func color(for index: Int, highlights: [Int]) -> Color {
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

struct TextContent: Identifiable {
  let id: String
  let words: [Word]
  let highlightedWords: [Int]

  init(text: String, highlightedWords: [Int]) {
    self.id = UUID().uuidString
    self.words = text
      .split(separator: " ")
      .enumerated()
      .map { offset, element in
        Word(String(element), offset: offset)
      }

    self.highlightedWords = highlightedWords
  }

  struct Word: Identifiable {
    let id: String
    let offset: Int
    let content: String

    init(_ content: String, offset: Int) {
      self.id = UUID().uuidString
      self.offset = offset
      self.content = content
    }
  }
}
