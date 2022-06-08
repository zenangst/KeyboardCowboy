import SwiftUI

struct ColorPalette: View {
  private let colorStrings: [String] = [
    "#EB5545", "#F2A23C", "#F9D64A", "#6BD35F", "#3984F7",
    "#B263EA", "#5D5FDE", "#A78F6D", "#98989D", "#EB4B63"]

  var items: [GridItem] {
    Array(repeating: .init(.fixed(size)), count: 5)
  }

  @Binding var group: WorkflowGroup
  var size: CGFloat

  var body: some View {
    LazyVGrid(columns: items, spacing: 10) {
      ForEach(colorStrings, id: \.self) { hex in
        ZStack {
          Circle()
            .fill(Color(group.color == hex ? .white : .clear))

          Circle()
            .fill(Color(hex: hex))
            .frame(width: size, height: size)
            .onTapGesture {
              group.color = hex
            }
            .padding(2)
        }
      }
    }
  }
}

struct ColorPalette_Previews: PreviewProvider {
  static var previews: some View {
    ColorPalette(group: .constant(WorkflowGroup.designTime()),
                 size: 48)
  }
}
