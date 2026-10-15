import AppKit
import Foundation
import SwiftUI

public struct TrashedAppItem: Identifiable, Equatable {
    public let id: String // Bundle ID or path
    public let name: String
    public let trashUrl: URL
    public let icon: NSImage
    public let leftoversCount: Int
    public let leftoversSizeBytes: Int64
    public let leftoverPaths: [URL]
    
    public static func == (lhs: TrashedAppItem, rhs: TrashedAppItem) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
public final class TrashWatcherService: ObservableObject {
    public static let shared = TrashWatcherService()
    
    @Published public var currentAlert: TrashedAppItem? = nil
    @Published public var isCleaning: Bool = false
    @Published public var cleanSuccess: Bool = false
    
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var knownTrashApps: Set<String> = []
    private var alertPanel: NSPanel?
    
    private let trashUrl = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")
    
    public init() {
        startWatching()
    }
    
    deinit {
        source?.cancel()
    }
    
    public func startWatching() {
        // Inicializa el conjunto de apps ya presentes en Papelera para no alertar de cosas viejas
        scanCurrentTrash(initial: true)
        
        let path = trashUrl.path
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }
        
        let s = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .attrib],
            queue: DispatchQueue.main
        )
        
        s.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                self?.scanCurrentTrash(initial: false)
            }
        }
        
        s.setCancelHandler { [weak self] in
            guard let self = self, self.fileDescriptor >= 0 else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }
        
        s.resume()
        self.source = s
    }
    
    public func stopWatching() {
        source?.cancel()
        source = nil
    }
    
    public func scanCurrentTrash(initial: Bool) {
        guard let items = try? FileManager.default.contentsOfDirectory(at: trashUrl, includingPropertiesForKeys: nil) else {
            return
        }
        
        for item in items where item.pathExtension.lowercased() == "app" {
            let itemName = item.lastPathComponent
            
            if initial {
                knownTrashApps.insert(itemName)
                continue
            }
            
            if !knownTrashApps.contains(itemName) {
                knownTrashApps.insert(itemName)
                // Se detectó una nueva app movida a la papelera!
                triggerAlert(for: item)
                break
            }
        }
    }
    
    public func triggerAlert(for appUrl: URL) {
        let appName = appUrl.deletingPathExtension().lastPathComponent
        let infoPlist = appUrl.appendingPathComponent("Contents/Info.plist")
        
        var bundleId = appUrl.lastPathComponent
        if let plistData = try? Data(contentsOf: infoPlist),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
            if let id = plist["CFBundleIdentifier"] as? String {
                bundleId = id
            }
        }
        
        let icon = NSWorkspace.shared.icon(forFile: appUrl.path)
        let (leftovers, leftoverSize) = findResidualFiles(for: bundleId, appName: appName)
        
        let alertItem = TrashedAppItem(
            id: bundleId,
            name: appUrl.lastPathComponent,
            trashUrl: appUrl,
            icon: icon,
            leftoversCount: leftovers.count,
            leftoversSizeBytes: leftoverSize,
            leftoverPaths: leftovers
        )
        
        self.currentAlert = alertItem
        self.cleanSuccess = false
        showFloatingNotification(for: alertItem)
    }
    
    public func simulateTrashDetection(appName: String = "WinZip.app") {
        let fakeIcon = NSWorkspace.shared.icon(forFile: "/Applications/Safari.app")
        let alertItem = TrashedAppItem(
            id: "com.winzip.WinZip-Mac",
            name: appName,
            trashUrl: trashUrl.appendingPathComponent(appName),
            icon: fakeIcon,
            leftoversCount: 8,
            leftoversSizeBytes: 142 * 1024 * 1024,
            leftoverPaths: []
        )
        self.currentAlert = alertItem
        self.cleanSuccess = false
        showFloatingNotification(for: alertItem)
    }
    
    public func ignoreAlert() {
        closeNotification()
        currentAlert = nil
    }
    
    public func uninstallWithLeftovers() async {
        guard let alert = currentAlert else { return }
        isCleaning = true
        
        // 1. Eliminar residuos en Library
        for residue in alert.leftoverPaths {
            try? FileManager.default.removeItem(at: residue)
        }
        
        // 2. Eliminar bundle de la papelera si existe
        if FileManager.default.fileExists(atPath: alert.trashUrl.path) {
            try? FileManager.default.removeItem(at: alert.trashUrl)
        }
        
        isCleaning = false
        cleanSuccess = true
        
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        closeNotification()
        currentAlert = nil
    }
    
    private func findResidualFiles(for bundleId: String, appName: String) -> ([URL], Int64) {
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
        
        let fm = FileManager.default
        let simpleName = appName.replacingOccurrences(of: ".app", with: "")
        
        for dir in targetDirs {
            guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
                continue
            }
            for item in contents {
                let lower = item.lastPathComponent.lowercased()
                let matchesId = lower.contains(bundleId.lowercased())
                let matchesName = lower.contains(simpleName.lowercased()) && simpleName.count > 3
                if matchesId || matchesName {
                    matched.append(item)
                    totalSize += calculateSize(at: item)
                }
            }
        }
        return (matched, totalSize)
    }
    
    private func calculateSize(at url: URL) -> Int64 {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        if !isDir.boolValue {
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            return (attrs?[.size] as? Int64) ?? 0
        }
        var size: Int64 = 0
        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys) {
            for case let fileURL as URL in enumerator {
                if let res = try? fileURL.resourceValues(forKeys: Set(keys)), res.isDirectory == false {
                    size += Int64(res.fileSize ?? 0)
                }
            }
        }
        return size
    }
    
    private func showFloatingNotification(for item: TrashedAppItem) {
        if alertPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 185),
                styleMask: [.nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .statusBar
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.animationBehavior = .utilityWindow
            self.alertPanel = panel
        }
        
        let contentView = TrashAlertView(item: item)
        alertPanel?.contentView = NSHostingView(rootView: contentView)
        
        // Posicionar en la esquina superior derecha justo debajo de la barra de menú
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 360
            let y = screenFrame.maxY - 195
            alertPanel?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        alertPanel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func closeNotification() {
        alertPanel?.orderOut(nil)
    }
}
