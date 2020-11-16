import SwiftUI

struct ColorView: View {
  @Binding private var color: String
  @State private var padding = CGFloat(0)

  private var selectAction: (String) -> Void

  init(_ color: Binding<String>, selectAction: @escaping (String) -> Void) {
    _color = color
    self.selectAction = selectAction
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(Color.white)
      Circle()
        .fill(Color(hex: color))
        .padding(padding)
    }
    .onTapGesture {
      selectAction(color)
    }
    .onHover(perform: { hovering in
      padding = hovering ? 2 : 0
    })
    .frame(minWidth: 48, minHeight: 48)
  }
}

struct ColorPalette_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    ColorView(.constant("#f00"), selectAction: { _ in })
      .frame(width: 48, height: 48, alignment: .center)
  }
}
