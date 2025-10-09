import SwiftUI

struct WorkspaceIcon: View {
  struct Variant {
    let showSymbol: Bool
    let fillGradient: LinearGradient
    let firstOverlay: LinearGradient
    let secondOverlay: LinearGradient

    nonisolated static let regular: Variant = .init(
      showSymbol: false,
      fillGradient: LinearGradient(stops: [
        .init(color: Color.black, location: 0.0),
        .init(color: Color(.black), location: 0.6),
        .init(color: Color(.systemPurple.blended(withFraction: 0.6, of: .white)!), location: 1.0),
      ], startPoint: .topLeading, endPoint: .bottom),
      firstOverlay: LinearGradient(stops: [
        .init(color: Color.blue, location: 0.5),
        .init(color: Color(.systemTeal.blended(withFraction: 0.3, of: .white)!), location: 1.0),
      ], startPoint: .topTrailing, endPoint: .bottomTrailing),
      secondOverlay: LinearGradient(stops: [
        .init(color: Color(.systemGreen.blended(withFraction: 0.3, of: .white)!), location: 0.2),
        .init(color: Color.clear, location: 0.8),
      ], startPoint: .topTrailing, endPoint: .bottomLeading),
    )

    nonisolated static let activatePrevious: Variant = .init(
      showSymbol: true,
      fillGradient: LinearGradient(stops: [
        .init(color: Color(.systemPurple), location: 0.0),
        .init(color: Color(.black), location: 0.6),
        .init(color: Color(.systemPurple.blended(withFraction: 0.3, of: .white)!), location: 1.0),
      ], startPoint: .topLeading, endPoint: .bottom),
      firstOverlay: LinearGradient(stops: [
        .init(color: Color.systemPink, location: 0.5),
        .init(color: Color(.systemPurple.blended(withFraction: 0.3, of: .white)!), location: 1.0),
      ], startPoint: .topTrailing, endPoint: .bottomTrailing),
      secondOverlay: LinearGradient(stops: [
        .init(color: Color(.systemOrange.blended(withFraction: 0.1, of: .red)!), location: 0.2),
        .init(color: Color.clear, location: 0.8),
      ], startPoint: .topTrailing, endPoint: .bottomLeading),
    )

    nonisolated static let dynamic: Variant = .init(
      showSymbol: false,
      fillGradient: LinearGradient(stops: [
        .init(color: Color(.systemPurple), location: 0.0),
        .init(color: Color(.black), location: 0.6),
        .init(color: Color(.systemPurple.blended(withFraction: 0.3, of: .white)!), location: 1.0),
      ], startPoint: .topLeading, endPoint: .bottom),
      firstOverlay: LinearGradient(stops: [
        .init(color: Color.systemPink, location: 0.5),
        .init(color: Color(.black.blended(withFraction: 0.3, of: .white)!), location: 1.0),
      ], startPoint: .topTrailing, endPoint: .bottomTrailing),
      secondOverlay: LinearGradient(stops: [
        .init(color: Color(.systemPink.blended(withFraction: 0.1, of: .red)!), location: 0.2),
        .init(color: Color.clear, location: 0.8),
      ], startPoint: .topTrailing, endPoint: .bottomLeading),
    )
  }

  let variant: Variant
  let size: CGFloat

  nonisolated init(_ variant: Variant, size: CGFloat) {
    self.variant = variant
    self.size = size
  }

  var body: some View {
    Rectangle()
      .fill(variant.fillGradient)
      .overlay {
        variant.firstOverlay
          .opacity(0.6)
      }
      .overlay {
        variant.secondOverlay
      }
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .overlay {
        WorkspaceIconIllustration(size: size)
      }
      .overlay(alignment: .center) {
        SymbolView(size: size)
          .opacity(variant.showSymbol ? 1 : 0)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

private struct SymbolView: View {
  let size: CGFloat
  var body: some View {
    LinearGradient(stops: [
      .init(color: Color(nsColor: .white).opacity(0.8), location: 0.6),
      .init(color: Color(nsColor: .gray), location: 1.0),
    ], startPoint: .topLeading, endPoint: .bottom)
      .mask {
        ZStack {
          Image(systemName: "arrowshape.turn.up.backward.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size * 0.35)
            .offset(x: -size * 0.015, y: -size * 0.015)
        }
      }
      .shadow(color: Color(nsColor: .systemPink.blended(withFraction: 0.4, of: .black)!), radius: 2, y: 1)
  }
}

struct WorkspaceIconIllustration: View {
  let size: CGFloat
  var body: some View {
    let spacing = size * 0.05
    HStack(spacing: spacing) {
      Group {
        WorkspaceIllustration(kind: .quarters, size: size)
        WorkspaceIllustration(kind: .leftQuarters, size: size)
        WorkspaceIllustration(kind: .fill, size: size)
        WorkspaceIllustration(kind: .rightQuarters, size: size)
      }
      .compositingGroup()
      .shadow(radius: 2, y: 2)
      .frame(width: size / 1.75, height: size / 1.75)
    }
    .padding(.vertical, size * 0.2)
    .offset(x: size * 0.3125)
  }
}

struct WorkspaceIllustration: View {
  enum Kind {
    case leftQuarters
    case quarters
    case rightQuarters
    case fill
  }

  let kind: Kind
  let size: CGFloat
  var body: some View {
    RoundedRectangle(cornerRadius: size * 0.125)
      .fill(Color.white.opacity(0.4))
      .clipShape(RoundedRectangle(cornerRadius: size * 0.125))
      .overlay {
        ZStack {
          switch kind {
          case .leftQuarters: WorkspaceLeftQuarters(size: size)
          case .quarters: WorkspaceQuarters(size: size)
          case .rightQuarters: WorkspaceRightQuarters(size: size)
          case .fill: WorkspaceFill(size: size)
          }
        }
      }
  }
}

private struct WorkspaceQuarters: View {
  let size: CGFloat
  var body: some View {
    let cornerRadius: CGFloat = size * 0.0015
    let opacity: CGFloat = 0.8
    let spacing = size * 0.045
    let clipShapeSize = size * 0.045
    HStack(spacing: spacing) {
      VStack(spacing: spacing) {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.white.opacity(opacity))
          .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.white.opacity(opacity))
          .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
      }
      VStack(spacing: spacing) {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.white.opacity(opacity))
          .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.white.opacity(opacity))
          .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
      }
    }
    .padding(spacing)
  }
}

private struct WorkspaceLeftQuarters: View {
  let size: CGFloat
  var body: some View {
    let cornerRadius: CGFloat = size * 0.0015
    let opacity: CGFloat = 0.8
    let spacing = size * 0.045
    let clipShapeSize = size * 0.045
    HStack(spacing: spacing) {
      VStack(spacing: spacing) {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.white.opacity(1))
          .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
      }
      VStack(spacing: spacing) {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.white.opacity(opacity))
          .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.white.opacity(0.6))
          .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
      }
    }
    .padding(spacing)
  }
}

private struct WorkspaceRightQuarters: View {
  let size: CGFloat
  var body: some View {
    let cornerRadius: CGFloat = size * 0.0015
    let opacity = 0.8
    let spacing = size * 0.045
    let clipShapeSize = size * 0.045
    HStack(spacing: spacing) {
      VStack(spacing: spacing) {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.white.opacity(opacity))
          .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.white.opacity(opacity))
          .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
      }
      VStack(spacing: spacing) {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.white.opacity(opacity))
          .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
      }
    }
    .padding(spacing)
  }
}

private struct WorkspaceFill: View {
  let size: CGFloat
  var body: some View {
    let cornerRadius: CGFloat = size * 0.065
    let spacing = size * 0.045
    let clipShapeSize = size * 0.045
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(Color.white.opacity(0.8))
      .clipShape(RoundedRectangle(cornerRadius: clipShapeSize))
      .padding(spacing)
  }
}

#Preview {
  IconPreview { WorkspaceIcon(.activatePrevious, size: $0) }
  IconPreview { WorkspaceIcon(.dynamic, size: $0) }
  IconPreview { WorkspaceIcon(.regular, size: $0) }
}
