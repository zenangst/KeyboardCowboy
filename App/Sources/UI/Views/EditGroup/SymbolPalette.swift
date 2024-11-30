import SwiftUI

struct SymbolPalette: View {
  private let symbols: [String] = [
    "app.connected.to.app.below.fill",
    "app.dashed",
    "applescript",
    "aqi.medium",
    "archivebox",
    "arrow.trianglehead.turn.up.right.diamond",
    "autostartstop",
    "bolt",
    "book",
    "bookmark",
    "calendar",
    "checkmark.seal",
    "cloud",
    "flame",
    "flowchart",
    "folder",
    "keyboard",
    "laptopcomputer",
    "link",
    "macwindow",
    "map",
    "message",
    "music.note",
    "pencil.tip",
    "rainbow",
    "safari",
    "sparkles",
    "star",
    "swirl.circle.righthalf.filled",
    "tag",
    "terminal",
    "touchid",
  ]

  var items: [GridItem] {
    Array(repeating: .init(.fixed(size)), count: 5)
  }

  @Binding var group: WorkflowGroup
  var size: CGFloat

  var body: some View {
    ScrollView {
      LazyVGrid(columns: items, spacing: 10) {
        ForEach(symbols, id: \.self) { symbol in
          Circle()
            .fill(Color(group.symbol == symbol ? .white : .clear))
            .overlay {
              Circle()
                .stroke(Color.white, lineWidth: 1.5)
                .frame(width: size - 4, height: size - 4)
                .overlay(
                  Image(systemName: symbol)
                    .foregroundStyle(group.symbol == symbol ? .black : .white)
                )
                .padding(4)
            }
            .contentShape(Circle())
            .onTapGesture {
              group.symbol = symbol
            }
        }
      }
    }
  }
}

struct SymbolPalette_Previews: PreviewProvider {
  static var previews: some View {
    SymbolPalette(group: .constant(WorkflowGroup.designTime()), size: 32)
  }
}
