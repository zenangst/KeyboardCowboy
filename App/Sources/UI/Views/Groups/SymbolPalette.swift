import SwiftUI

struct SymbolPalette: View {
  private let symbols: [String] = [
    "autostartstop",
    "app.dashed",
    "applescript",
    "folder",
    "app.connected.to.app.below.fill",
    "flowchart",
    "terminal",
    "laptopcomputer",
    "safari",
    "archivebox",
    "flame",
    "calendar",
    "book",
    "bookmark",
    "link",
    "pencil.tip",
    "sparkles",
    "cloud",
    "checkmark.seal",
    "music.note",
    "star",
    "tag",
    "bolt",
    "macwindow"
  ]

  var items: [GridItem] {
    Array(repeating: .init(.fixed(size)), count: 5)
  }

  @Binding var group: WorkflowGroup
  var size: CGFloat

  var body: some View {
    LazyVGrid(columns: items, spacing: 10) {
      ForEach(symbols, id: \.self) { symbol in
        ZStack {
          Circle()
            .fill(Color(group.symbol == symbol ? .white : .clear))

          Circle()
            .fill(Color(.windowBackgroundColor))
            .frame(width: size, height: size)
            .overlay(Image(systemName: symbol))
            .onTapGesture {
              group.symbol = symbol
            }
            .padding(2)
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
