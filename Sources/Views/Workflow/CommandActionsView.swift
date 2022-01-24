import SwiftUI

struct CommandActionsView: View {
    var body: some View {
      HStack(spacing: 2) {
        Text("Edit").foregroundColor(Color.accentColor)
        Text("|")
        Text("Reveal").foregroundColor(Color.accentColor)
        Text("|")
        Text("Run").foregroundColor(Color.accentColor)
      }
      .font(Font.caption)
      .foregroundColor(Color(.secondaryLabelColor))
    }
}

struct CommandActionsView_Previews: PreviewProvider {
    static var previews: some View {
        CommandActionsView()
    }
}
