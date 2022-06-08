import Apps
import SwiftUI

struct ApplicationTriggerListView: View {
  @ObserveInjection var inject
  enum Action {
    case add(Application)
    case remove(Application)
  }

  let action: (Action) -> Void
  @StateObject var applicationStore: ApplicationStore
  @Binding var applicationTriggers: [ApplicationTrigger]
  @State var selectedApplication: Application?
  @Namespace var namespace

  var body: some View {
    VStack {
      HStack {
        ApplicationPickerView(applicationStore, selection: $selectedApplication)
        Button("Add") {
          guard let selectedApplication = selectedApplication else { return }
          action(.add(selectedApplication))
        }.disabled(selectedApplication == nil)
      }
      LazyVStack {
        ForEach($applicationTriggers) { applicationTrigger in
          ResponderView(applicationTrigger, namespace: namespace) { responder in
            HStack {
              ApplicationTriggerView(trigger: applicationTrigger)
              Button(action: { action(.remove(applicationTrigger.application.wrappedValue)) },
                     label: { Image(systemName: "xmark.circle") })
              .buttonStyle(PlainButtonStyle())
              .padding([.trailing], 16)
            }
            .background(Color(.windowBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .background(ResponderBackgroundView(responder: responder))
          }.onDeleteCommand {
            applicationTriggers.removeAll(where: { $0.id == applicationTrigger.id })
          }
        }
      }
    }
    .frame(alignment: .topLeading)
    .enableInjection()
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
    ApplicationTriggerListView(
      action: { _ in },
      applicationStore: applicationStore,
      applicationTriggers: .constant([
        .init(application: Application.finder())
      ])
    )
  }
}
