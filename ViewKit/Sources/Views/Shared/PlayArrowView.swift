import SwiftUI

struct PlayArrowView: View {
  var body: some View {
    ZStack {
      Circle()
        .fill(Color(.controlAccentColor))
      Text("▶︎")
        .foregroundColor(Color(NSColor.white))
    }
    .shadow(color: Color(NSColor.black).opacity(0.25), radius: 1, x: 1, y: 2)
    .frame(width: 16, height: 16, alignment: .center)
    .offset(x: 7, y: 7)
  }
}
