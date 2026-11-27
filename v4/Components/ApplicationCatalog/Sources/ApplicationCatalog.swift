import Foundation

public enum ApplicationCatalog {
  public static func defaultDirectories() -> [URL] {
    let files = FileManager.default
    return [
      files.urls(for: .applicationDirectory, in: .userDomainMask).first,
      files.urls(for: .allApplicationsDirectory, in: .localDomainMask).first,
      files.urls(for: .coreServiceDirectory, in: .systemDomainMask).first,
    ].compactMap { $0 } + [
      "/Developer/Applications",
      "/Network/Applications",
      "/Network/Developer/Applications",
      "/Users/Shared/Applications",
      "/System/Applications",
      "/System/Volumes/Preboot/Cryptexes/App/System/Applications",
    ].map { URL(filePath: $0, directoryHint: .isDirectory) }
  }

  public static func applications(additionalDirectories: [URL] = []) async -> [Application] {
    scan(defaultDirectories() + additionalDirectories)
  }

  static func scan(_ roots: [URL]) -> [Application] {
    let files = FileManager.default
    var visitedRoots: Set<String> = []
    var visitedApps: Set<String> = []
    var apps: [(name: String, application: Application)] = []

    for root in roots {
      let root = root.standardizedFileURL
      guard visitedRoots.insert(root.path).inserted,
            let entries = files.enumerator(at: root, includingPropertiesForKeys: [],
                                           options: [.skipsHiddenFiles, .producesRelativePathURLs])
      else { continue }

      for case let url as URL in entries {
        let depth = entries.level
        let isApp = url.hasDirectoryPath && url.pathExtension == "app"
        // Xcode ships tools such as Instruments in its bundle. Regular app
        // bundles are leaves; there is no need to enumerate their contents.
        let isXcodePath = (isApp || depth > 2) && url.relativePath.contains("Xcode")
        if depth > (isXcodePath ? 5 : 2) {
          entries.skipDescendants()
          continue
        }
        guard isApp else { continue }

        if !isXcodePath {
          entries.skipDescendants()
        }

        let absoluteURL = url.absoluteURL
        guard visitedApps.insert(absoluteURL.path).inserted,
              let application = parse(absoluteURL, files: files)
        else { continue }

        apps.append((application.displayName.lowercased(), application))
      }
    }
    return apps.sorted { $0.name < $1.name }.map(\.application)
  }

  private static func parse(_ url: URL, files: FileManager) -> Application? {
    guard let bundle = Bundle(url: url),
          let info = bundle.infoDictionary,
          let identifier = info["CFBundleIdentifier"] as? String,
          let name = (info["CFBundleName"] as? String) ?? (info["CFBundleDisplayName"] as? String),
          info["CFBundleIconFile"] != nil || info["CFBundleIconName"] != nil || info["CFBundleIcons"] != nil
    else { return nil }

    let path = bundle.bundlePath
    var app = Application(bundleIdentifier: identifier, bundleName: name,
                          displayName: files.displayName(atPath: path), path: path)
    app.metadata.isAgent = info["LSUIElement"] != nil
    app.metadata.isElectron = bundle.privateFrameworksURL.map {
      files.fileExists(atPath: $0.appending(path: "Electron Framework.framework").path)
    } ?? false
    app.metadata.isSafariWebApp = identifier.hasPrefix("com.apple.Safari.WebApp.")
    return app
  }
}
