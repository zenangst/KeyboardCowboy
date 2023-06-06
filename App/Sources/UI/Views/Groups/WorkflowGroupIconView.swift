import SwiftUI

struct WorkflowGroupIconView: View {
  @Binding var group: WorkflowGroup
  @State var isHovering: Bool = false

  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(hex: group.color))
      .contentShape(Circle())
      .overlay(overlay)
      .frame(width: size, height: size, alignment: .center)
      .shadow(
        color: Color(.sRGBLinear, white: 0, opacity: 0.2),
        radius: 1,
        y: 1)
      .onHover { value in
        self.isHovering = value
      }
  }

  @ViewBuilder
  var overlay: some View {
    ZStack {
      Image(systemName: group.symbol)
        .resizable()
        .renderingMode(.template)
        .aspectRatio(contentMode: .fill)
        .foregroundColor(.white)
        .frame(width: 12, height: 12, alignment: .center)
      Text("Edit")
        .font(.caption)
        .offset(x: 0, y: 15)
        .opacity(isHovering ? 1.0 : 0.0)
    }
    .cursorOnHover(.pointingHand)
  }
}

struct WorkflowGroupIconView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowGroupIconView(group: .constant(WorkflowGroup.designTime()),
                          size: 48)
  }
}
