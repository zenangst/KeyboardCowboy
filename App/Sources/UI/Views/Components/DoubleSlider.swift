import Bonzai
import SwiftUI

struct DoubleSlider: View {
  @ObserveInjection private var inject
  @State private var popoverIsActive: Bool = false
  @Binding var value: Double
  let placeholderText: String
  let min: Double
  let max: Double
  let step: Double

  var body: some View {
    Button {
      popoverIsActive.toggle()
    } label: {
      Group {
        if value == 0 {
          Text(placeholderText)
        } else {
          Text(String(format: "%.2f", value))
            .fontDesign(.monospaced)
        }
      }
      .font(.caption)
    }
    .popover(isPresented: $popoverIsActive, arrowEdge: .bottom, content: {
      HStack {
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

        Button(action: {
          value = 0
          popoverIsActive = false
        }, label: {
          Image(systemName: "xmark")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 10, height: 12)
        })
        .environment(\.buttonBackgroundColor, .systemRed)
      }
      .padding(.horizontal, 6)
    })
    .enableInjection()
  }
}

#Preview {
  DoubleSlider(value: .constant(0.5), placeholderText: "None", min: 0.05, max: 1, step: 0.05)
}
