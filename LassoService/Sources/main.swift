import Foundation

if #available(macOS 14.0, *) {
  let serviceName = "com.zenangst.Keyboard-Cowboy.LassoService"
  _ = try XPCListener(service: serviceName, targetQueue: DispatchQueue.main) { request in
    request.accept { (message: XPCReceivedMessage) in
      if let info = try? message.decode(as: XPCMessage.self) {
        message.reply(XPCMessage(text: "Ohai!"))
        print("Sent a message back!")
      }

      return nil
    }
  }

  dispatchMain()
}
