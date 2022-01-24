import SwiftUI

struct WorkflowGroupView: View {
  @State var group: WorkflowGroup

  var body: some View {
    HStack {
      Rectangle()
        .fill(Color(hex: group.color))
        .overlay(overlay)
        .clipped(antialiased: true)
        .cornerRadius(24, antialiased: true)
        .frame(width: 24, height: 24, alignment: .center)
        .shadow(
          color: Color(.sRGBLinear, white: 0, opacity: 0.2),
          radius: 1,
          y: 1)
      Text(group.name)
    }
  }

  @ViewBuilder
  var overlay: some View {
    Image(systemName: group.symbol)
      .resizable()
      .renderingMode(.template)
      .aspectRatio(contentMode: .fill)
      .foregroundColor(.white)
      .frame(width: 12, height: 12, alignment: .center)
  }
}

struct WorkflowGroupView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowGroupView(group: WorkflowGroup.designTime())
  }
}
