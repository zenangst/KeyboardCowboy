import SwiftUI

struct WindowTilingIcon: View {
  let kind: WindowTiling
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemPurple.blended(withFraction: 0.6, of: .white)!), location: 0.3),
          .init(color: Color(.cyan), location: 0.6),
          .init(color: Color.blue, location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
      )
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemPurple.blended(withFraction: 0.3, of: .white)!), location: 0.5),
          .init(color: Color.blue, location: 1.0),
        ], startPoint: .topTrailing, endPoint: .bottomTrailing)
        .opacity(0.6)
      }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemOrange.blended(withFraction: 0.3, of: .white)!), location: 0.2),
          .init(color: Color.clear, location: 0.8),
        ], startPoint: .topTrailing, endPoint: .bottomLeading)
      }
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(nsColor: .black.blended(withFraction: 0.2, of: .white)!), location: 0.705),
          .init(color: Color(nsColor: .black.blended(withFraction: 0.5, of: .white)!), location: 0.705),
          .init(color: Color(nsColor: .white), location: 0.8),
        ], startPoint: .top, endPoint: .bottom)
        .mask {
          Image(systemName: "laptopcomputer")
            .resizable()
            .scaledToFit()
            .fontWeight(.thin)
        }
        .shadow(color: Color(nsColor: .black.blended(withFraction: 0.4, of: .black)!), radius: 2, y: 1)
        .frame(width: size * 0.98, height: size)
        .offset(x: size * 0.01, y: size * 0.01)
      }
      .overlay {
        WindowTilingKindView(kind: kind, size: size)
          .frame(width: size * 0.65, height: size * 0.4)
          .offset(y: -size * 0.01)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

private struct WindowTilingKindView: View {
  let kind: WindowTiling
  let size: CGFloat

  var body: some View {
    let spacing: CGFloat = size * 0.035
    switch kind {
    case .left:
      HStack(spacing: 0) {
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
          .opacity(0.0)
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .right:
      HStack(spacing: 0) {
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
          .opacity(0.0)
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .top:
      VStack(spacing: 0) {
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
          .opacity(0.0)
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .bottom:
      VStack(spacing: 0) {
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
          .opacity(0.0)
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .topLeft:
      VStack(spacing: 0) {
        HStack(spacing: 0) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
        }
        HStack(spacing: 0) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
        }
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .topRight:
      VStack(spacing: 0) {
        HStack(spacing: 0) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
        }
        HStack(spacing: 0) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
        }
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .bottomLeft:
      VStack(spacing: 0) {
        HStack(spacing: 0) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
        }
        HStack(spacing: 0) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
        }
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .bottomRight:
      VStack(spacing: 0) {
        HStack(spacing: 0) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
        }
        HStack(spacing: 0) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
        }
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .center:
      Rectangle().fill(Color.white)
        .iconShape(size * 0.15)
        .padding(.horizontal, size * 0.075)
        .padding(.vertical, size * 0.035)
        .opacity(0.7)
    case .fill:
      Rectangle().fill(Color.white)
        .iconShape(size * 0.15)
        .padding(size * 0.01)
        .opacity(0.7)
    case .zoom:
      Rectangle().fill(Color.white)
        .iconShape(size * 0.2)
        .opacity(0.7)
    case .arrangeLeftRight:
      HStack(spacing: spacing) {
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
          .opacity(0.7)
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .arrangeRightLeft:
      HStack(spacing: spacing) {
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
          .opacity(0.7)
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .arrangeTopBottom:
      VStack(spacing: spacing) {
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
          .opacity(0.7)
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .arrangeBottomTop:
      VStack(spacing: spacing) {
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
          .opacity(0.7)
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .arrangeLeftQuarters:
      HStack(spacing: spacing) {
        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
        VStack(spacing: spacing) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
        }
        .opacity(0.7)
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .arrangeRightQuarters:
      HStack(spacing: spacing) {
        VStack(spacing: spacing) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
        }
        .opacity(0.7)

        Rectangle().fill(Color.white)
          .iconShape(size * 0.15)
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .arrangeTopQuarters:
      VStack(spacing: spacing) {
        HStack(spacing: spacing) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
        }
        HStack(spacing: spacing) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0.7)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0.7)
        }
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .arrangeBottomQuarters:
      VStack(spacing: spacing) {
        HStack(spacing: spacing) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0.7)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
            .opacity(0.7)
        }
        HStack(spacing: spacing) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
        }
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .arrangeQuarters:
      VStack(spacing: spacing) {
        HStack(spacing: spacing) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
        }
        HStack(spacing: spacing) {
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
          Rectangle().fill(Color.white)
            .iconShape(size * 0.15)
        }
      }
      .padding(size * 0.01)
      .opacity(0.7)
    case .previousSize:
      Rectangle().fill(Color.white)
        .iconShape(size * 0.15)
        .overlay {
          Color.black.opacity(0.4)
          .mask {
            ZStack {
              Image(systemName: "app")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.2)
              Image(systemName: "arrowshape.turn.up.backward.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.1)
                .offset(x: -size * 0.005, y: -size * 0.005)
            }
          }
        }
        .padding(.horizontal, size * 0.075)
        .padding(.vertical, size * 0.035)
        .opacity(0.7)
    }
  }
}

#Preview("Left") {
  IconPreview { WindowTilingIcon(kind: .left, size: $0) }
}

#Preview("Right") {
  IconPreview { WindowTilingIcon(kind: .right, size: $0) }
}

#Preview("Top") {
  IconPreview { WindowTilingIcon(kind: .top, size: $0) }
}

#Preview("Bottom") {
  IconPreview { WindowTilingIcon(kind: .bottom, size: $0) }
}

#Preview("Top Left") {
  IconPreview { WindowTilingIcon(kind: .topLeft, size: $0) }
}

#Preview("Top Right") {
  IconPreview { WindowTilingIcon(kind: .topRight, size: $0) }
}

#Preview("Bottom Left") {
  IconPreview { WindowTilingIcon(kind: .bottomLeft, size: $0) }
}

#Preview("Bottom Right") {
  IconPreview { WindowTilingIcon(kind: .bottomRight, size: $0) }
}

#Preview("Left & Right") {
  IconPreview { WindowTilingIcon(kind: .arrangeLeftRight, size: $0) }
}

#Preview("Right & Left") {
  IconPreview { WindowTilingIcon(kind: .arrangeRightLeft, size: $0) }
}

#Preview("Top & Bottom") {
  IconPreview { WindowTilingIcon(kind: .arrangeTopBottom, size: $0) }
}

#Preview("Bottom & Top") {
  IconPreview { WindowTilingIcon(kind: .arrangeBottomTop, size: $0) }
}


#Preview("Left & Quarters") {
  IconPreview { WindowTilingIcon(kind: .arrangeLeftQuarters, size: $0) }
}

#Preview("Right & Quarters") {
  IconPreview { WindowTilingIcon(kind: .arrangeRightQuarters, size: $0) }
}

#Preview("Top & Quarters") {
  IconPreview { WindowTilingIcon(kind: .arrangeTopQuarters, size: $0) }
}

#Preview("Bottom & Quarters") {
  IconPreview { WindowTilingIcon(kind: .arrangeBottomQuarters, size: $0) }
}

#Preview("Quarters") {
  IconPreview { WindowTilingIcon(kind: .arrangeQuarters, size: $0) }
}

#Preview("Center") {
  IconPreview { WindowTilingIcon(kind: .center, size: $0) }
}

#Preview("Fill") {
  IconPreview { WindowTilingIcon(kind: .fill, size: $0) }
}

#Preview("Zoom") {
  IconPreview { WindowTilingIcon(kind: .zoom, size: $0) }
}

#Preview("Previous Size") {
  IconPreview { WindowTilingIcon(kind: .previousSize, size: $0) }
}
