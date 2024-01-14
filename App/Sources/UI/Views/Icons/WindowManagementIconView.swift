import Bonzai
import Inject
import SwiftUI

struct WindowManagementIconView: View {
  @ObserveInjection var inject
  let size: CGFloat
  @Binding var stacked: Bool

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      VStack {
        windowControls()
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(sidebarBackground())

      Divider()
        .background(Color(.systemGray))
      Divider()
        .background(Color.white)

      window()
        .frame(width: size * 0.182)
    }
    .background()
    .compositingGroup()
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .frame(width: size, height: size)
    .fixedSize()
    .stacked($stacked, color: Color(.systemRed), size: size)
    .enableInjection()
  }

  func sidebarBackground() -> some View {
    Rectangle()
      .fill(Color(nsColor: NSColor(red:0.94, green:0.71, blue:0.51, alpha:1.00)))
      .overlay {
        LinearGradient(stops: [
          .init(color: Color.clear, location: 0.1),
          .init(color: Color(.systemYellow).opacity(0.8), location: 0.2),
          .init(color: Color(nsColor: NSColor(red:0.94, green:0.71, blue:0.51, alpha:1.00)), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)

        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(nsColor: NSColor(red:0.80, green:0.93, blue:0.99, alpha:1.00)),
                      location: 0.0),
                .init(color: .clear, location: 0.75),
              ]),
              startPoint: .topTrailing,
              endPoint: .bottomLeading
            )
          )

        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(.systemPink).opacity(0.4), location: 0.0),
                .init(color: .clear, location: 1.0),
              ]),
              startPoint: .bottomLeading,
              endPoint: .leading
            )
          )

        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(.systemRed).opacity(0.6), location: 0.0),
                .init(color: .clear, location: 0.25),
              ]),
              startPoint: .bottomLeading,
              endPoint: .trailing
            )
          )
      }
      .blur(radius: 0.2)
      .compositingGroup()
  }

  func windowControls() -> some View {
    HStack(spacing: size * 0.0_55) {
      Circle()
        .fill(
          LinearGradient(stops: [
            .init(color: Color(nsColor: NSColor(red:0.88, green:0.19, blue:0.14, alpha:1.00)), location: 0.1),
            .init(color: Color(.systemRed), location: 1)
          ],
                         startPoint: .top,
                         endPoint: .bottom)
        )
        .overlay {
          Image(systemName: "xmark")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(Color.black.opacity(0.4))
            .shadow(color: Color(.red).opacity(0.7), radius: 1)
            .padding(size * 0.0_4)
        }
        .frame(height: size * 0.15)
      Circle()
        .fill(
          LinearGradient(colors: [
            Color(nsColor: NSColor(red:1.00, green:0.98, blue:0.37, alpha:1.00)),
            Color(.systemYellow)
          ], startPoint: .top, endPoint: .bottom)
        )
        .overlay {
          Image(systemName: "minus")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(Color.black.opacity(0.4))
            .shadow(color: Color(.white).opacity(0.7), radius: 1)
            .padding(size * 0.0_4)
        }
        .frame(height: size * 0.15)
      Circle()
        .fill(
          LinearGradient(colors: [
            Color(nsColor: NSColor(red:0.44, green:0.94, blue:0.39, alpha:1.00)),
            Color(.systemGreen)
          ], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay {
          Image(systemName: "arrow.up.left.and.arrow.down.right")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(Color.black.opacity(0.4))
            .shadow(color: Color(.green).opacity(0.7), radius: 1)
            .padding(size * 0.0_4)
        }
        .frame(height: size * 0.15)
    }
    .compositingGroup()
    .shadow(radius: size * 0.0_05, y: 1)
    .fontWeight(.bold)
    .padding([.top, .leading, .trailing], size * 0.0_5)
    .frame(height: size * 0.25)
  }

  func window() -> some View {
    VStack(spacing: 0) {
      Rectangle()
        .frame(height: size * 0.30)
      Divider()
        .background(Color.white)
      Divider()
        .background(Color(.systemGray))
      Rectangle()
        .fill(Color(.systemGray).opacity(0.4))
    }
    .background(Color(.white))
  }
}

struct WindowManagementIconView_Previews: PreviewProvider {
  @State static var stacked: Bool = true
  static var previews: some View {
    VStack {
      HStack {
        WindowManagementIconView(size: 128, stacked: .constant(false))
        WindowManagementIconView(size: 64, stacked: .constant(false))
        WindowManagementIconView(size: 32, stacked: .constant(false))
      }
      HStack {
        WindowManagementIconView(size: 128, stacked: .constant(true))
        WindowManagementIconView(size: 64, stacked: .constant(true))
        WindowManagementIconView(size: 32, stacked: .constant(true))
      }
    }
    .onTapGesture {
      stacked.toggle()
    }
    .padding()
  }
}
