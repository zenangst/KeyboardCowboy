//
//  HotSwiftUI.swift
//  HotSwiftUI
//
//  Created by John Holdsworth on 03/01/2021.
//  Copyright © 2017 John Holdsworth. All rights reserved.
//
//  $Id: //depot/HotSwiftUI/Sources/HotSwiftUI/HotSwiftUI.swift#26 $
//

import SwiftUI
#if DEBUG
import Combine

public let injectionObserver = InjectionObserver.shared

public class InjectionObserver: ObservableObject {
    public static let shared = InjectionObserver()
    public static var appResources =
        "/Applications/InjectionIII.app/Contents/Resources/"
    @Published var injectionNumber = 0
    var cancellable: AnyCancellable? = nil
    let publisher = PassthroughSubject<Void, Never>()
    init() {
        _ = loadInjectionOnce // .enableInjection() optional with Xcode 16+
        cancellable = NotificationCenter.default.publisher(for:
            Notification.Name("INJECTION_BUNDLE_NOTIFICATION"))
            .sink { [weak self] change in
            self?.injectionNumber += 1
            self?.publisher.send()
        }
    }
}

private var loadInjectionOnce: Void = {
    guard objc_getClass("InjectionClient") == nil else {
        return
    }
    // If project has a "Build Phase" running script (works on device):
    // /Applications/InjectionIII.app/Contents/Resources/copy_bundle.sh
    if let path = Bundle.main.path(forResource:
            "iOSInjection", ofType: "bundle") ??
        Bundle.main.path(forResource:
            "macOSInjection", ofType: "bundle"),
        Bundle(path: path)?.load() == true {
        return
    }
    #if os(macOS) || targetEnvironment(macCatalyst)
    let bundleName = "macOSInjection.bundle"
    #elseif os(tvOS)
    let bundleName = "tvOSInjection.bundle"
    #elseif os(visionOS)
    let bundleName = "xrOSInjection.bundle"
    #elseif os(watchOS)
    let bundleName = "watchOSInjection.bundle"
    #elseif targetEnvironment(simulator)
    let bundleName = "iOSInjection.bundle"
    #else
    let bundleName = "maciOSInjection.bundle"
    #endif
    var bundlePath = InjectionObserver.appResources+bundleName
    for app in ["InjectionIII", "InjectionNext"] {
        bundlePath = bundlePath.replacingOccurrences(of: "InjectionIII", with: app)
        if let bundle = Bundle(path: bundlePath), bundle.load() { return }
    }
    print("""
            ⚠️ Could not load injection bundle from \(bundlePath). \
            Have you downloaded the InjectionIII.app from either \
            https://github.com/johnno1962/InjectionIII/releases \
            or the Mac App Store? Build clean if you have been \
            using the HotReloading Swift Package from github.
            """)
}()

extension SwiftUI.View {
    public func eraseToAnyView() -> some SwiftUI.View {
        _ = loadInjectionOnce
        return AnyView(self)
    }
    public func enableInjection() -> some SwiftUI.View {
        return eraseToAnyView()
    }
    public func loadInjection() -> some SwiftUI.View {
        return eraseToAnyView()
    }
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
            .onReceive(InjectionObserver.shared.publisher, perform: bumpState)
            .eraseToAnyView()
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct ObserveInjection: DynamicProperty {
    @ObservedObject private var iO = InjectionObserver.shared
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}

#else
extension SwiftUI.View {
    @inline(__always)
    public func eraseToAnyView() -> some SwiftUI.View { return self }
    @inline(__always)
    public func enableInjection() -> some SwiftUI.View { return self }
    @inline(__always)
    public func loadInjection() -> some SwiftUI.View { return self }
    @inline(__always)
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct ObserveInjection {
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}
#endif
