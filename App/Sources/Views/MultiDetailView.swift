import SwiftUI

struct MultiDetailView: View {
  @ObserveInjection var inject
  @EnvironmentObject var groupStore: GroupStore
  let models: [DetailViewModel]
  let count: Int

  init(_ models: [DetailViewModel], count: Int) {
    self.models = models
    self.count = count
  }

  var body: some View {
    VStack(spacing: 24) {
      Text("Multiple commands selected: \(count)")
        .font(.title)
      ZStack {
        ForEach(Array(zip(models.indices, models)), id: \.1.id) { offset, element in
          let offset = Double(offset)
          let scaleDelta = -(offset * 0.025)
          let offsetDelta: CGFloat = (offset * 10)
          HStack {
            ZStack {
              ForEach(element.commands) { command in
                if let icon = command.icon {
                  IconView(icon: icon, size: .init(width: 32, height: 32))
                }
              }
            }

            Text(element.name)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(16)
          .frame(maxWidth: .infinity)
          .background(Color.init(nsColor: .textBackgroundColor).cornerRadius(8))
          .shadow(color: .black.opacity(0.2), radius: 4)
          .padding()
          .opacity(1 - scaleDelta)
          .zIndex(100 - offset)
          .offset(y: offsetDelta)
          .scaleEffect(1 + scaleDelta)
        }
      }
      .frame(maxHeight: 100)

      HStack {
        Menu {
          Button("Move", action: {})
          Button("Copy", action: {})
        } label: {
          Button("Move", action: {})
        }
        .frame(maxWidth: 100)

        Text("to:")

        Menu {
          ForEach(groupStore.groups) { group in
            Button(group.name, action: {})
          }
        } label: {
          Button("---", action: {})
        }

        Button("Perform", action: {})
      }
      .buttonStyle(AppButtonStyle())
      .padding()

      Spacer()
    }
    .padding(.top, 92)
    .debugEdit()
    .enableInjection()
  }
}

//struct MultiDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        MultiDetailView()
//    }
//}
