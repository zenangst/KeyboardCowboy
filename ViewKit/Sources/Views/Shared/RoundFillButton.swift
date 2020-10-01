import SwiftUI

struct RoundFillButton: View {
  let title: String
  let color: Color

  var body: some View {
    ZStack {
      Circle()
        .fill(color)
        .frame(maxWidth: 16, maxHeight: 16)

      Text(title)
        .bold()
        .foregroundColor(Color(.white))
        .offset(x: 0, y: -1)
    }
  }
}

struct RoundFillButton_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        RoundFillButton(title: "+", color: Color(.systemGreen))
        RoundFillButton(title: "-", color: Color(.systemRed))
      }
    }
}
