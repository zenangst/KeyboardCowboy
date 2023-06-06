import SwiftUI

struct FeatureBetaModifier<BetaView>: ViewModifier where BetaView: View {
  private let issueNumber: Int?
  private let text: String
  private let betaView: () -> BetaView
  @State private var isHovered: Bool = false
  @State private var isShown: Bool = false

  init(text: String, issueNumber: Int? = nil, betaView: @autoclosure @escaping () -> BetaView) {
    self.init(text: text, issueNumber: issueNumber, betaView: betaView)
  }

  init(text: String, issueNumber: Int? = nil, betaView: @escaping () -> BetaView = { Text("Beta") }) {
    self.text = text
    self.issueNumber = issueNumber
    self.betaView = betaView
  }


  func body(content: Content) -> some View {
    content
      .overlay(alignment: .trailing,
               content: {
        betaView()
          .contentShape(RoundedRectangle(cornerRadius: 4))
          .font(.subheadline.bold())
          .scaleEffect(isHovered ? 1 : 0.7)
          .shadow(color: .black.opacity(isHovered ? 0.5 : 0.33), radius: isHovered ? 4 : 2)
          .popover(isPresented: $isShown) {
            HStack(spacing: 4) {
              Text("BETA")
                .shadow(color: Color(.systemYellow.withSystemEffect(.deepPressed)), radius: 0, x: 1, y: 1)
                .font(.headline)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(8)
                .foregroundColor(.black)
                .background(
                  LinearGradient(stops: [
                    .init(color: Color(.systemYellow.withSystemEffect(.deepPressed)), location: 0.0),
                    .init(color: Color(.systemYellow), location: 1.0)
                  ], startPoint: .top, endPoint: .bottom)
                )
              VStack {
                Text(text)
                  .padding(8)
                  .frame(maxWidth: .infinity, alignment: .leading)

                if let issueNumber {
                  HStack {
                    Spacer()
                    Button("GitHub issue: #\(issueNumber)") {
                      NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/issues/\(issueNumber)")!)
                    }
                    .buttonStyle(AppButtonStyle())
                  }
                }
              }
              .padding(8)

              VStack {
                Button(action: { isShown = false },
                       label: {
                  Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                })
                .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGray, grayscaleEffect: true)))
                .frame(width: 16, alignment: .top)
                .padding([.top, .trailing], 8)
                Spacer()
              }
            }
            .background(
              LinearGradient(colors: [
                Color(.black).opacity(0.25),
                Color(.black).opacity(0.5),
              ], startPoint: .top, endPoint: .bottom)
              .padding(-16)
            )
          }
          .animation(.spring(), value: isHovered)
          .onHover(perform: { newValue in
            isHovered = newValue
          })
          .onTapGesture {
            isShown.toggle()
          }
          .onTapGesture {
            Swift.print("foo")
          }
      })
  }
}

extension View {
  func betaFeature<Content>(_ text: String, issueNumber: Int? = nil, content: @escaping () -> Content) -> some View where Content: View {
    self
      .modifier(FeatureBetaModifier(text: text, issueNumber: issueNumber, betaView: content))
  }
}

struct FeatureBetaModifier_Previews: PreviewProvider {
    static var previews: some View {
        Text("This is a text")
        .modifier(FeatureBetaModifier(text: "Description"))
        .padding()
    }
}
