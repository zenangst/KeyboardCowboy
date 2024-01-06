import Bonzai
import SwiftUI

struct EditGroupIconView: View {
  @Binding var group: WorkflowGroup
  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      VStack(alignment: .leading) {
        ZenLabel(.detail, content: { Text("Color")})
        ColorPalette(group: $group, size: 32)
      }
      Divider()
      VStack(alignment: .leading) {
        ZenLabel(.detail, content: { Text("Color")})
        SymbolPalette(group: $group, size: 32)
      }
    }
    .padding()
  }
}

struct EditGroupIconView_Previews: PreviewProvider {
  static var previews: some View {
    EditGroupIconView(group: .constant(WorkflowGroup.designTime()))
  }
}
