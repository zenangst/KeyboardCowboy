import Bonzai
import SwiftUI

struct DoubleSlider: View {
  @State private var popoverIsActive: Bool = false
  @Binding var value: Float
  let min: Float
  let max: Float
  let step: Float

  var body: some View {
    Button {
      popoverIsActive.toggle()
    } label: {
      Text(String(format: "%.2f", value))
    }
    .popover(isPresented: $popoverIsActive, arrowEdge: .bottom, content: {
      Slider(
        value: $value,
        in: min...max,
        step: step,
        label: {  },
        minimumValueLabel: { Text(String(format: "%.2f", min)) },
        maximumValueLabel: { Text(String(format: "%.2f", max)) },
        onEditingChanged: { _ in }
      )
      .frame(minWidth: 200)
      .padding(8)
    })
  }
}

#Preview {
  DoubleSlider(value: .constant(0.5), min: 0.05, max: 1, step: 0.05)
}
