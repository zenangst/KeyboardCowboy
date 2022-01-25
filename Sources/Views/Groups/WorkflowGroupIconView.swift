import SwiftUI

struct WorkflowGroupIconView: View {
  @State var group: WorkflowGroup

  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(hex: group.color))
      .overlay(overlay)
      .clipped(antialiased: true)
      .cornerRadius(size, antialiased: true)
      .frame(width: size, height: size, alignment: .center)
      .shadow(
        color: Color(.sRGBLinear, white: 0, opacity: 0.2),
        radius: 1,
        y: 1)
  }

  @ViewBuilder
  var overlay: some View {
    Image(systemName: group.symbol)
      .resizable()
      .renderingMode(.template)
      .aspectRatio(contentMode: .fill)
      .foregroundColor(.white)
      .frame(width: 15, height: 15, alignment: .center)
  }
}

struct WorkflowGroupIconView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowGroupIconView(group: WorkflowGroup.designTime(),
                          size: 48)
  }
}
