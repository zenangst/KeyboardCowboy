import SwiftUI

struct SymbolPalette: View {
  @ObserveInjection var inject
  private let symbols: [String] = [
    "folder",
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
    .enableInjection()
  }
}

struct SymbolPalette_Previews: PreviewProvider {
  static var previews: some View {
    SymbolPalette(group: .constant(WorkflowGroup.designTime()), size: 32)
  }
}
