import AppKit
import Foundation

public struct InstalledApp: Identifiable {
    public let id: String // Bundle ID
    public let name: String
    public let version: String
    public let bundleUrl: URL
    public var appSizeBytes: Int64 = 0
    public var leftoversSizeBytes: Int64 = 0
    public var leftoverPaths: [URL] = []
    public var isSelected: Bool = false
    
    public var totalSizeBytes: Int64 {
        appSizeBytes + leftoversSizeBytes
    }
}

@MainActor
public final class AppUninstallerService: ObservableObject {
    public static let shared = AppUninstallerService()
    
    @Published public var apps: [InstalledApp] = []
    @Published public var isScanning: Bool = false
    @Published public var isUninstalling: Bool = false
    @Published public var statusMessage: String = ""
    
    private let fileManager = FileManager.default
    
    public init() {}
    
    public func scanApps() async {
        isScanning = true
        statusMessage = "Buscando aplicaciones instaladas..."
        
        var discovered: [InstalledApp] = []
        let searchDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications")
        ]
        
        for dir in searchDirs {
            guard let contents = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
                continue
            }
            
            for item in contents where item.pathExtension == "app" {
                let infoPlist = item.appendingPathComponent("Contents/Info.plist")
                guard let plistData = try? Data(contentsOf: infoPlist),
                      let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
                    continue
                }
                
                let bundleId = (plist["CFBundleIdentifier"] as? String) ?? item.deletingPathExtension().lastPathComponent
                let appName = (plist["CFBundleName"] as? String) ?? (plist["CFBundleDisplayName"] as? String) ?? item.deletingPathExtension().lastPathComponent
                let version = (plist["CFBundleShortVersionString"] as? String) ?? "1.0"
                
                let appSize = calculateDirectorySize(at: item)
                let (leftovers, leftoverSize) = findLeftovers(for: bundleId, appName: appName)
                
                discovered.append(InstalledApp(
                    id: bundleId,
                    name: appName,
                    version: version,
                    bundleUrl: item,
                    appSizeBytes: appSize,
                    leftoversSizeBytes: leftoverSize,
                    leftoverPaths: leftovers
                ))
            }
        }
        
        discovered.sort { $0.totalSizeBytes > $1.totalSizeBytes }
        self.apps = discovered
        self.isScanning = false
        self.statusMessage = "\(discovered.count) aplicaciones encontradas"
    }
    
    private func findLeftovers(for bundleId: String, appName: String) -> ([URL], Int64) {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        var matched: [URL] = []
        var totalSize: Int64 = 0
        
        let targetDirs = [
            home.appendingPathComponent("Library/Application Support"),
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent("Library/Preferences"),
            home.appendingPathComponent("Library/Saved Application State"),
            home.appendingPathComponent("Library/Containers")
        ]
        
        for dir in targetDirs {
            guard let contents = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
                continue
            }
            
            for item in contents {
                let lastComponent = item.lastPathComponent
                let lower = lastComponent.lowercased()
                let matchesId = lower.contains(bundleId.lowercased())
                let matchesName = lower.contains(appName.lowercased()) && appName.count > 3
                
                if matchesId || matchesName {
                    matched.append(item)
                    totalSize += calculateDirectorySize(at: item)
                }
            }
        }
        
        return (matched, totalSize)
    }
    
    public func uninstall(app: InstalledApp) async {
        isUninstalling = true
        statusMessage = "Moviendo a la papelera \(app.name)..."
        
        // Trash the bundle
        try? fileManager.trashItem(at: app.bundleUrl, resultingItemURL: nil)
        
        // Trash all leftovers
        for residue in app.leftoverPaths {
            try? fileManager.trashItem(at: residue, resultingItemURL: nil)
        }
        
        apps.removeAll { $0.id == app.id }
        isUninstalling = false
        statusMessage = "\(app.name) desinstalado por completo"
    }
    
    private func calculateDirectorySize(at url: URL) -> Int64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            let attrs = try? fileManager.attributesOfItem(atPath: url.path)
            return (attrs?[.size] as? Int64) ?? 0
        }
        
        var totalSize: Int64 = 0
        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)) else { continue }
            if resourceValues.isDirectory == false {
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
        }
        
        return totalSize
    }
}
