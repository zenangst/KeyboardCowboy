import CoreGraphics

extension Operation {
  struct NextDisplay: Sendable {
    let displays: [WindowManagement.Display]
    var mode: WindowManagement.DisplayTransferMode = .center

    func requestedFrame(for original: CGRect) -> CGRect? {
      guard displays.count > 1,
            let current = WindowManagement.displayIndex(for: original, on: displays) else { return nil }

      for offset in 1 ..< displays.count {
        let display = displays[(current + offset) % displays.count]
        guard display.bounds != displays[current].bounds,
              let usable = WindowManagement.usableBounds(of: display) else { continue }

        switch mode {
        case .center:
          return WindowManagement.centeredFrame(original, in: usable)
        case .relative:
          guard let source = WindowManagement.usableBounds(of: displays[current]) else { return nil }

          return relativeFrame(original, from: source, to: usable)
        }
      }
      return nil
    }

    private func relativeFrame(_ original: CGRect, from source: CGRect, to destination: CGRect) -> CGRect? {
      let xScale = destination.width / source.width
      let yScale = destination.height / source.height
      let width = min(original.width * xScale, destination.width)
      let height = min(original.height * yScale, destination.height)
      let x = destination.minX + (original.minX - source.minX) * xScale
      let y = destination.minY + (original.minY - source.minY) * yScale
      // Request whole-point origins for the CG settling check. AX/CG may
      // otherwise quantize the fractional position in different directions.
      let result = CGRect(
        x: fittedOrigin(x, minimum: destination.minX, maximum: destination.maxX - width),
        y: fittedOrigin(y, minimum: destination.minY, maximum: destination.maxY - height),
        width: width, height: height,
      )
      return WindowManagement.isUsable(result) ? result : nil
    }

    private func fittedOrigin(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
      let lower = minimum.rounded(.up)
      let upper = maximum.rounded(.down)
      if lower <= upper { return min(max(value.rounded(), lower), upper) }
      return min(max(value, minimum), max(minimum, maximum))
    }
  }
}
