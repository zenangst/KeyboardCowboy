import SwiftUI

struct SymbolView: View {
  @Binding private var symbol: String
  @State private var padding = CGFloat(0)

  private var selectAction: (String) -> Void

  init(_ symbol: Binding<String>, selectAction: @escaping (String) -> Void) {
    _symbol = symbol
    self.selectAction = selectAction
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(Color.white)
      Circle()
        .fill(Color(.textBackgroundColor))
        .padding(padding)
      Image(systemName: symbol)
        .padding(padding)
    }
    .onTapGesture {
      selectAction(symbol)
    }
    .onHover(perform: { hovering in
      padding = hovering ? 2 : 0
    })
    .frame(minWidth: 48, minHeight: 48)
  }
}

struct SymbolView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    SymbolView(.constant("folder"), selectAction: { _ in })
      .frame(width: 48, height: 48, alignment: .center)
  }
}
