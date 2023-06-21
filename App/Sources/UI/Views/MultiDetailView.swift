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
      VStack {
        Text("Multiple commands selected: \(count)")
          .font(.title)
        ZStack {
          ForEach(Array(zip(models.indices, models)), id: \.1.id) { offset, element in
            let offset = Double(offset)
            let scaleDelta = -(offset * 0.025)
            let offsetDelta: CGFloat = (offset * 5)
            HStack {
              ZStack {
                ForEach(element.commands) { command in
                  if let icon = command.meta.icon {
                    IconView(icon: icon, size: .init(width: 32, height: 32))
                  }
                }
              }

              Text(element.name)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.init(nsColor: .windowBackgroundColor).cornerRadius(8))
            .shadow(color: .black.opacity(0.2), radius: 4)
            .padding(8)
            .opacity(1 - scaleDelta)
            .zIndex(100 - offset)
            .offset(y: offsetDelta)
            .scaleEffect(1 + scaleDelta)
          }
        }
        .padding(8)
        .padding(8)
        .background(Color.init(nsColor: .textBackgroundColor).cornerRadius(8))
        .frame(maxHeight: 100)
      }
      .padding(.horizontal, 8)
      .padding(.bottom)
      .padding(.top, 32)
      .background(alignment: .bottom, content: {
        Rectangle()
          .fill(
            LinearGradient(stops: [
              .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.3, of: .white)!), location: 0.0),
              .init(color: Color(nsColor: .windowBackgroundColor), location: 0.01),
              .init(color: Color(nsColor: .windowBackgroundColor), location: 0.8),
              .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.3, of: .black)!), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
          )
          .mask(
            Canvas(rendersAsynchronously: true) { context, size in
              context.fill(
                Path(CGRect(origin: .zero, size: CGSize(width: size.width,
                                                        height: size.height - 12))),
                with: .color(Color(.black))
              )

              context.fill(Path { path in
                path.move(to: CGPoint(x: size.width / 2, y: size.height - 12))
                path.addLine(to: CGPoint(x: size.width / 2 - 24, y: size.height - 12))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 2))
                path.addLine(to: CGPoint(x: size.width / 2 + 24, y: size.height - 12))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 12))
              }, with: .color(Color(.black)))
            }
          )
          .compositingGroup()
          .shadow(color: Color.white.opacity(0.2), radius: 0, y: 1)
          .shadow(radius: 2, y: 2)
      })

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
    .debugEdit()
  }
}

//struct MultiDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        MultiDetailView()
//    }
//}
