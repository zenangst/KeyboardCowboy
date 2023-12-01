import Bonzai
import Inject
import SwiftUI

struct UserModesView: View {
  enum Action {
    case add(UserMode.ID)
    case delete(UserMode.ID)
    case rename(UserMode.ID, String)
  }
  @ObserveInjection var inject
  @EnvironmentObject var publisher: ConfigurationPublisher
  @State private var isAddingNew = false
  let onAction: (Action) -> Void

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Label("User Modes", image: "")
        Spacer()
        Button(action: { isAddingNew = true }, label: {
          Image(systemName: "plus")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 8)
        })
        .buttonStyle(.zen(.init(calm: true, color: .systemGreen, grayscaleEffect: .constant(true))))
        .popover(isPresented: $isAddingNew, arrowEdge: .bottom, content: {
          AddUserModeView(action: { newName in
            isAddingNew = false
            onAction(.add(newName))
          })
          .padding()
        })
      }

      FlowLayout {
        ForEach(publisher.data.userModes) { userMode in
          FlowItem(userMode: userMode, onAction: { }, onDelete: {
            onAction(.delete(userMode.id))
          }, onRename: {
            onAction(.rename(userMode.id, $0))
          })
          .transition(.fadeAndGrow.animation(.smooth))
        }
      }
    }
    .enableInjection()
  }
}

struct FlowLayout: Layout {
  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

    var totalHeight: CGFloat = 0
    var totalWidth: CGFloat = 0

    var lineWidth: CGFloat = 0
    var lineHeight: CGFloat = 0

    for size in sizes {
      if lineWidth + size.width > proposal.width ?? 0 {
        totalHeight += lineHeight
        lineWidth = size.width
        lineHeight = size.height
      } else {
        lineWidth += size.width
        lineHeight = max(lineHeight, size.height)
      }

      totalWidth = max(totalWidth, lineWidth)
    }

    totalHeight += lineHeight

    return .init(width: totalWidth, height: totalHeight)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

    var lineX = bounds.minX
    var lineY = bounds.minY
    var lineHeight: CGFloat = 0

    for index in subviews.indices {
      if lineX + sizes[index].width > (proposal.width ?? 0) {
        lineY += lineHeight
        lineHeight = 0
        lineX = bounds.minX
      }

      subviews[index].place(
        at: .init(
          x: lineX + sizes[index].width / 2,
          y: lineY + sizes[index].height / 2
        ),
        anchor: .center,
        proposal: ProposedViewSize(sizes[index])
      )

      lineHeight = max(lineHeight, sizes[index].height)
      lineX += sizes[index].width
    }
  }
}

struct FlowItem: View {
  @ObserveInjection var inject
  @State var isHovered: Bool = false
  @State var areYouSure: Bool = false
  @State var rename: Bool = false
  @State var userMode: UserMode

  let onAction: () -> Void
  let onDelete: () -> Void
  let onRename: (String) -> Void

  init(
    userMode: UserMode,
    onAction: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    onRename: @escaping (String) -> Void
  ) {
    self.userMode = userMode
    self.onAction = onAction
    self.onDelete = onDelete
    self.onRename = onRename
  }

  var body: some View {
    Button(action: { rename = true }, label: {
      Text(userMode.name)
        .font(.caption2)
    })
    .overlay(alignment: .topTrailing, content: {
      Button(action: {
        areYouSure = true
      }, label: {
        Image(systemName: "xmark.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 12)
      })
      .buttonStyle(.borderless)
      .offset(x: 4, y: -4)
      .scaleEffect(isHovered ? 1 : 0.5)
      .opacity(isHovered ? 1 : 0)
      .animation(.smooth, value: isHovered)
    })
    .buttonStyle(.zen(.init()))
    .onHover(perform: { hovering in
      isHovered = hovering
    })
    .contextMenu(ContextMenu(menuItems: {
      Button(action: {
        areYouSure = true
      }, label: {
        Text("Delete")
      })
    }))
    .popover(isPresented: $rename, content: {
      HStack {
        TextField("", text: $userMode.name)
          .onSubmit {
            rename = false
          }
      }
      .padding(6)
      .buttonStyle(.regular)
      .font(.caption)
      .onDisappear {
        onRename(userMode.name)
      }
    })
    .popover(isPresented: $areYouSure, content: {
      HStack {
        Text("Are you sure?")
          .padding(.leading, 6)
        Spacer()
        Button(action: { areYouSure = false }, label: {
          Text("Cancel")
        })
        Button(action: { 
          areYouSure = true
          onDelete()
        }, label: {
          Text("Delete")
        })
        .buttonStyle(.destructive)
      }
      .padding(6)
      .buttonStyle(.regular)
      .font(.caption)
    })
    .enableInjection()
  }
}

//struct FlowLayout<Content: View>: View {
//  @ObserveInjection var inject
//  let items: [Content]
//  let spacing: CGFloat
//  @State private var totalHeight: CGFloat = 0
//
//  var body: some View {
//    GeometryReader { geometry in
//      self.generateContent(in: geometry)
//    }
//    .frame(height: totalHeight)
//  }
//
//  private func generateContent(in geometry: GeometryProxy) -> some View {
//    var width = CGFloat.zero
//    var height = CGFloat.zero
//    var lastHeight = CGFloat.zero
//
//    return ZStack(alignment: .topLeading) {
//      ForEach(Array(items.enumerated()), id: \.offset) { index, item in
//        item
//          .alignmentGuide(.leading, computeValue: { d in
//            if (abs(width - d.width) > geometry.size.width) {
//              width = 0
//              height -= lastHeight
//            }
//            let result = width
//            if index == items.count - 1 {
//              width = 0
//            } else {
//              width -= d.width + spacing
//            }
//
//            return result
//          })
//          .alignmentGuide(.bottom, computeValue: { d in
//            let result = height
//            if index == items.count - 1 {
//              height = 0 // last item
//            } else {
//              lastHeight = d.height + spacing
//            }
//            return result
//          })
//          .frame(alignment: .topLeading)
//      }
//    }
//    .background(viewHeightReader($totalHeight))
//    .enableInjection()
//  }
//
//  private func viewHeightReader(_ height: Binding<CGFloat>) -> some View {
//    return GeometryReader { geometryReader in
//      Color.clear
//        .preference(key: ViewHeightKey.self, value: geometryReader.size.height)
//        .onPreferenceChange(ViewHeightKey.self) { value in
//          height.wrappedValue = value
//        }
//    }
//  }
//
//  private struct ViewHeightKey: PreferenceKey {
//    static var defaultValue: CGFloat { 0 }
//    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//      value = max(value, nextValue())
//    }
//  }
//}

#Preview {
  UserModesView(onAction: { _ in })
}
