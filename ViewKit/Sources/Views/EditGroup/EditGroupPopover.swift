import Foundation
import SwiftUI

struct EditGroupPopover: View {
  private let firstRowColors: [String] = ["#EB5545", "#F2A23C", "#F9D64A", "#6BD35F", "#3984F7"]
  private let secondRowColors: [String] = ["#B263EA", "#5D5FDE", "#A78F6D", "#98989D", "#EB4B63"]

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

  var selectColor: (String) -> Void
  var selectSymbol: (String) -> Void

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 8) {
        ForEach(firstRowColors, id: \.self) { color in
          ColorView(.constant(color), selectAction: selectColor)
        }
      }
      HStack(spacing: 8) {
        ForEach(secondRowColors, id: \.self) { color in
          ColorView(.constant(color), selectAction: selectColor)
        }
      }

      Divider()

      LazyVGrid(columns: [
                  GridItem(.fixed(48)),
                  GridItem(.fixed(48)),
                  GridItem(.fixed(48)),
                  GridItem(.fixed(48)),
                  GridItem(.fixed(48)),
      ]) {
        ForEach(symbols, id: \.self) {
          SymbolView(.constant($0), selectAction: selectSymbol)
        }
      }
    }
  }
}

struct EditGroupPopover_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditGroupPopover(selectColor: { _ in }, selectSymbol: { _ in }).fixedSize()
  }
}
