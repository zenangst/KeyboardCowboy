import SwiftUI

struct RoundOutlinedButton: View {
  let title: String
  let color: Color

  var body: some View {
    ZStack {
      Circle()
        .stroke(color)
        .frame(maxWidth: 16, maxHeight: 16)

      Text(title)
        .bold()
        .foregroundColor(color)
        .offset(x: 0, y: -1)
    }
  }
}

struct RoundOutlinedButton_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        RoundOutlinedButton(title: "+", color: Color(.systemGreen))
        RoundOutlinedButton(title: "-", color: Color(.systemRed))
      }
    }
}
