import SwiftUI

struct WorkflowDisabledOverlay: View {
  private let isEnabled: Bool

  init(isEnabled: Bool) {
    self.isEnabled = isEnabled
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(Color.white)
        .frame(width: 14, height: 14)
      Image(systemName: "pause.circle.fill")
        .resizable()
        .foregroundStyle(Color.accentColor)
        .frame(width: 12, height: 12)
    }
    .opacity(!isEnabled ? 1 : 0)
  }
}
