import SwiftUI

struct NewCommandValidationView: View {
  @ObserveInjection var inject
  @Binding var validation: NewCommandValidation

  init(_ validation: Binding<NewCommandValidation>) {
    _validation = validation
  }

  var body: some View {
    Group {
      switch validation {
      case .invalid(let reason):
        GeometryReader { proxy in
          ZStack(alignment: .bottom) {
            let redColor = NSColor.systemRed
            VStack(spacing: 0) {
              RoundedRectangle(cornerRadius: 4)
                .stroke(Color(.systemRed.withAlphaComponent(0.5)), lineWidth: 2)
                .shadow(color: Color(redColor), radius: 2)
                .frame(width: proxy.size.width, height: proxy.size.height)
              if let reason {
                HStack {
                  Text(reason)
                    .font(.caption)
                    .padding()
                  Button(action: {
                    withAnimation { validation = .unknown }
                  }, label: {
                    Image(systemName: "xmark")
                      .resizable()
                      .frame(width: 8, height: 8)
                      .aspectRatio(1, contentMode: .fit)
                  })
                  .buttonStyle(.gradientStyle(config: .init(nsColor: .systemRed)))
                }
                .background(
                  GeometryReader { proxy in
                    ZStack {
                      Path { path in
                        path.move(to: CGPoint(x: proxy.size.width / 2, y: 0))
                        path.addLine(to: CGPoint(x: proxy.size.width / 2 - 16, y: 0))
                        path.addLine(to: CGPoint(x: proxy.size.width / 2, y: 8))
                        path.addLine(to: CGPoint(x: proxy.size.width / 2 + 16, y: 0))
                      }
                      .fill(Color(redColor))
                      .shadow(color: Color(.systemRed).opacity(0.6), radius: 4, y: 2)

                      LinearGradient(stops: [
                        .init(color: Color(redColor), location: 0.0),
                        .init(color: Color(redColor.blended(withFraction: 0.5, of: .black)!), location: 1.0),
                      ], startPoint: .top, endPoint: .bottom)
                      .cornerRadius(8)
                      .shadow(radius: 4)
                      .frame(width: proxy.size.width, height: proxy.size.height - 16)
                    }
                    .offset(x: 8, y: 0)
                  }
                )
              }
            }
          }
          .animation(.easeInOut, value: validation)
        }
      case .valid, .unknown, .needsValidation:
        EmptyView()
      }
    }
    .id(validation.rawValue)
    .enableInjection()
  }
}

struct NewCommandValidationView_Previews: PreviewProvider {
  static var cases: [NewCommandValidation] = [
    .invalid(reason: "Reason"),
    .invalid(reason: nil),
  ]

  static var previews: some View {
    Group {
      ForEach(cases) { validation in
        NewCommandValidationView(.constant(validation))
          .previewDisplayName(validation.rawValue)
      }
    }
  }
}
