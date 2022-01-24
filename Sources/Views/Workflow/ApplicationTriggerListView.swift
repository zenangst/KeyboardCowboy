import Apps
import SwiftUI

struct ApplicationTriggerListView: View {
  var applicationTriggers: [ApplicationTrigger]

  var body: some View {
    ForEach(applicationTriggers) { applicationTrigger in
      contextView(applicationTrigger.contexts)
    }
  }

  @ViewBuilder
  func contextView(_ contexts: Set<ApplicationTrigger.Context>) -> some View {
    HStack(spacing: 1) {
      if contexts.contains(.closed) {
        Circle().fill(Color(.systemRed))
          .frame(width: 6)
      }
      if contexts.contains(.launched) {
        Circle().fill(Color(.systemYellow))
          .frame(width: 6)
      }
      if contexts.contains(.frontMost) {
        Circle().fill(Color(.systemGreen))
          .frame(width: 6)
      }
    }
    .frame(height: 10)
    .padding(.horizontal, 1)
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .stroke(Color(NSColor.systemGray.withSystemEffect(.disabled)), lineWidth: 1)
    )
    .opacity(0.8)
  }
}

struct ApplicationTriggerListView_Previews: PreviewProvider {
  static var previews: some View {
    ApplicationTriggerListView(applicationTriggers: [])
  }
}
