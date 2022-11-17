import SwiftUI

struct EditGroupIconView: View {
  @ObserveInjection var inject
  @Binding var group: WorkflowGroup
  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      VStack(alignment: .leading) {
        Label("Color", image: "")
          .labelStyle(HeaderLabelStyle())
        ColorPalette(group: $group, size: 32)
      }
      Divider()
      VStack(alignment: .leading) {
        Label("Icon", image: "")
          .labelStyle(HeaderLabelStyle())
        SymbolPalette(group: $group, size: 32)
      }
    }
    .padding()
    .enableInjection()
  }
}

struct EditGroupIconView_Previews: PreviewProvider {
  static var previews: some View {
    EditGroupIconView(group: .constant(WorkflowGroup.designTime()))
  }
}
