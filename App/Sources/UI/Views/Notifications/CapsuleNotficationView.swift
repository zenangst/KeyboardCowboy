import Bonzai
import Inject
import SwiftUI

@MainActor
final class CapsuleNotificationPublisher: ObservableObject {
  enum State: Equatable {
    case idle
    case running
    case failure
    case success

    var foregroundColor: Color {
      switch self {
      case .running, .idle: .white
      case .failure: Color(.systemRed.withSystemEffect(.deepPressed))
      case .success: Color(.controlAccentColor.withSystemEffect(.deepPressed))
      }
    }

    var borderColor: Color {
      switch self {
      case .running, .idle: .gray
      case .failure: Color(.systemRed.withSystemEffect(.deepPressed))
      case .success: Color(.controlAccentColor.withSystemEffect(.deepPressed))
      }
    }

    var backgroundColor: Color {
      switch self {
      case .running, .idle: .black
      case .failure: Color.systemRed.blended(withFraction: 0.85, of: .black)
      case .success: Color(nsColor: .controlAccentColor).blended(withFraction: 0.45, of: .black)
      }
    }
  }

  var id: String
  @Published var text: String
  @Published var state: State

  init(text: String = "", id: String, state: State = .running) {
    self.id = id
    self.text = text
    self.state = state
  }

  @MainActor
  func publish(_ text: String, id: String, state: State) {
    self.id = id
    self.state = state
    self.text = text
  }
}

struct CapsuleNotificationView: View {
  @ObserveInjection var inject
  @ObservedObject var publisher: CapsuleNotificationPublisher
  @Namespace var namespace

  init(publisher: CapsuleNotificationPublisher) {
    self.publisher = publisher
  }

  var body: some View {
    Text(publisher.text.isEmpty ? " " : publisher.text)
      .font(.system(.title2, design: .rounded, weight: .regular))
      .padding(.leading, publisher.state == .running ?  24 : 0)
      .overlay(alignment: .leading) {
        ProgressView()
          .progressViewStyle(CustomProgressViewStyle())
          .frame(width: 18)
          .opacity(publisher.state == .running ? 1 : 0)
          .animation(nil, value: publisher.state)
      }
      .foregroundStyle(publisher.state.foregroundColor)
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .background(
        ZStack {
          Capsule(style: .continuous)
            .stroke(publisher.state.borderColor.opacity(0.2), lineWidth: 2)
            .padding(1)

          Capsule(style: .continuous)
            .stroke(publisher.state.borderColor.opacity(0.05), lineWidth: 2)
        }
          .opacity(publisher.state == .idle ? 0 : 1)
          .animation(.smooth(duration: 0.1), value: publisher.state)
      )
      .background(
        Capsule(style: .continuous)
          .fill(
            LinearGradient(stops: [
              .init(color: publisher.state.backgroundColor.opacity(0.8), location: 0),
              .init(color: publisher.state.backgroundColor.opacity(0.9), location: 0.8),
            ], startPoint: .top, endPoint: .bottom)
          )
          .opacity(publisher.state == .idle ? 0 : 1)
          .animation(.smooth(duration: 0.1), value: publisher.state)
      )
      .frame(minWidth: 128, maxWidth: .infinity)
      .opacity(publisher.state == .idle ? 0 : 1)
      .animation(.smooth(duration: 0.275), value: publisher.state)
  }
}

fileprivate struct CustomProgressViewStyle: ProgressViewStyle {
  @State private var isSpinning: Bool = false

  func makeBody(configuration: Configuration) -> some View {
    Circle()
      .trim(from: 0.2, to: 1.0)
      .stroke(
        AngularGradient(
          gradient: Gradient(colors: [
            Color(.controlAccentColor.withSystemEffect(.disabled)),
            .accentColor]),
          center: .center
        ),
        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
      )
      .padding(1)
      .rotationEffect(isSpinning ? .degrees(360) : .degrees(0))
      .animation(
        Animation.linear(duration: 1.0)
          .repeatForever(autoreverses: false),
        value: isSpinning
      )
      .onAppear {
        isSpinning = true
      }
  }
}

#Preview {
  let dynamicPublisher = CapsuleNotificationPublisher(text: "Running…", id: UUID().uuidString)

  return VStack(spacing: 4) {
    CapsuleNotificationView(publisher: dynamicPublisher)
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          dynamicPublisher.text = "Workflow successful."
          dynamicPublisher.state = .success
        }
      }
    ZenDivider()
    CapsuleNotificationView(publisher: CapsuleNotificationPublisher(text: "Running…", id: UUID().uuidString, state: .running))
    CapsuleNotificationView(publisher: CapsuleNotificationPublisher(text: "Workflow successful.", id: UUID().uuidString, state: .failure))
    CapsuleNotificationView(publisher: CapsuleNotificationPublisher(text: "Workflow successful.", id: UUID().uuidString, state: .success))
  }
  .padding(10)
}
