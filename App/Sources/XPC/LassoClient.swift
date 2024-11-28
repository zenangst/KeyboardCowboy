import Foundation

@available(macOS 14.0, *)
final class LassoClient {
  let session: XPCSession

  init() throws {
    let serviceName = "com.zenangst.Keyboard-Cowboy.LassoService"
    session = try XPCSession(xpcService: serviceName)
  }

  func send(_ text: String) {
    do {
      try session.send(XPCMessage(text: "Hello, world!"), replyHandler: { result in
        switch result {
        case .success(let result):
          let response = try? result.decode(as: XPCMessage.self)
          print("result", response)
        case .failure(let error):
          print(error)
        }
      })
    } catch {
      print("error", error)
    }
  }
}
