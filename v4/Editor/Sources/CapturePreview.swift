#if DEBUG
import SwiftUI

struct CapturePreview: View {
  let role: String
  let frame: CGRect

  init?(arguments: [String]) {
    guard arguments.count == 6, arguments[0] == "--capture-preview",
          let x = Double(arguments[2]), let y = Double(arguments[3]),
          let width = Double(arguments[4]), let height = Double(arguments[5]),
          x.isFinite, y.isFinite, width.isFinite, height.isFinite,
          width >= 0, height >= 0 else { return nil }

    role = arguments[1]
    frame = CGRect(x: x, y: y, width: width, height: height)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Captured Element").font(.headline)
      LabeledContent("Role", value: role.isEmpty ? "Unavailable" : role)
      LabeledContent("AX frame", value: String(describing: frame))
    }
    .padding(24)
    .frame(minWidth: 320)
  }
}
#endif
