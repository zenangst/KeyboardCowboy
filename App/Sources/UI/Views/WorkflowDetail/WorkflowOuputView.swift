import Bonzai
import SwiftUI

struct WorkflowOuputView: View {
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ZenLabel("Workflow Output")
      }
      VStack(spacing: 8) {
        HStack {
          Text("News")
          Spacer()
          Text("✅")
        }
        HStack {
          Text("Home Folder")
          Spacer()
          Text("✅")
        }
        HStack {
          Text("AppleScript.scpt")
          Spacer()
          Text("✅")
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color(.windowFrameTextColor).opacity(0.2), lineWidth: 2),
      )
    }
    .padding()
  }
}
