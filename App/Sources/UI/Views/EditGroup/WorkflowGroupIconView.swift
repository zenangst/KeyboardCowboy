import Bonzai
import SwiftUI

struct WorkflowGroupIconView: View {
  @ObservedObject var applicationStore: ApplicationStore
  @Binding var group: WorkflowGroup
  @State var isHovering: Bool = false

  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(hex: group.color))
      .contentShape(Circle())
      .overlay(Image(systemName: group.symbol)
        .resizable()
        .renderingMode(.template)
        .aspectRatio(contentMode: .fill)
        .foregroundColor(.white)
        .frame(width: 12, height: 12, alignment: .center))
      .overlay(ZStack {
        if let first = group.rule?.bundleIdentifiers.first,
           let app = applicationStore.application(for: first) {
          IconView(icon: Icon(app), size: .init(width: 24, height: 24))
            .allowsHitTesting(false)
        }
      })
//      .overlay(Text("Edit")
//        .font(.caption)
//        .offset(x: 0, y: 12)
//        .opacity(isHovering ? 1.0 : 0.0))
      .frame(width: size, height: size, alignment: .center)
      .shadow(
        color: Color(.sRGBLinear, white: 0, opacity: 0.2),
        radius: 1,
        y: 1)
      .cursorOnHover(.pointingHand)
      .onHover { value in
        self.isHovering = value
      }
  }
}

struct WorkflowGroupIconView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowGroupIconView(
      applicationStore: ApplicationStore.shared,
      group: .constant(WorkflowGroup.designTime()),
      size: 48
    )
  }
}
