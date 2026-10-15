import Foundation

public struct JunkSubItem: Identifiable {
    public let id: String
    public let name: String
    public let path: URL
    public var sizeBytes: Int64
    public var isSelected: Bool = true
}

public struct JunkCategory: Identifiable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let iconName: String
    public let accentColor: String
    public var rootPaths: [URL]
    public var sizeBytes: Int64 = 0
    public var isSelected: Bool = true
    public var subItems: [JunkSubItem] = []
    public var itemCount: Int = 0
}

@MainActor
public final class JunkCleanerService: ObservableObject {
    public static let shared = JunkCleanerService()
    
    @Published public var categories: [JunkCategory] = []
    @Published public var isScanning: Bool = false
    @Published public var isCleaning: Bool = false
    @Published public var currentScanningPath: String = ""
    @Published public var totalFoundBytes: Int64 = 0
    @Published public var totalCleanedSessionBytes: Int64 = 0
    @Published public var lastScanDate: Date?
    
    private let fileManager = FileManager.default
    
    public init() {
        setupDefaultCategories()
    }
    
    public func setupDefaultCategories() {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        
        // Darwin user cache path (/var/folders/.../C/)
        var darwinCacheUrl: URL? = nil
        var buf = [CChar](repeating: 0, count: 1024)
        if confstr(_CS_DARWIN_USER_CACHE_DIR, &buf, 1024) > 0 {
            let darwinPath = String(cString: buf)
            if !darwinPath.isEmpty {
                darwinCacheUrl = URL(fileURLWithPath: darwinPath)
            }
        }
        
        var userCachePaths = [home.appendingPathComponent("Library/Caches")]
        if let dUrl = darwinCacheUrl {
            userCachePaths.append(dUrl)
        }
        
        categories = [
            JunkCategory(
                id: "user_caches",
                name: "Cachés del Sistema y Apps",
                subtitle: "Archivos temporales del sistema, clang y cachés de aplicaciones.",
                iconName: "archivebox.fill",
                accentColor: "violet",
                rootPaths: userCachePaths
            ),
            JunkCategory(
                id: "developer",
                name: "Entorno de Desarrollo",
                subtitle: "Caché de paquetes npm, Yarn, pip y DerivedData de Xcode.",
                iconName: "hammer.fill",
                accentColor: "emerald",
                rootPaths: [
                    home.appendingPathComponent(".npm"),
                    home.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
                    home.appendingPathComponent("Library/Caches/Yarn"),
                    home.appendingPathComponent("Library/Caches/pip"),
                    home.appendingPathComponent(".cargo/registry/cache")
                ]
            ),
            JunkCategory(
                id: "browsers",
                name: "Navegadores Web",
                subtitle: "Cachés de navegación de Brave, Chrome, Safari y Arc.",
                iconName: "globe",
                accentColor: "cyan",
                rootPaths: [
                    home.appendingPathComponent("Library/Caches/BraveSoftware"),
                    home.appendingPathComponent("Library/Caches/Google/Chrome"),
                    home.appendingPathComponent("Library/Caches/com.apple.Safari"),
                    home.appendingPathComponent("Library/Caches/company.thebrowser.Browser")
                ]
            ),
            JunkCategory(
                id: "system_logs",
                name: "Registros y Diagnósticos",
                subtitle: "Informes de fallos, volcados de memoria y logs acumulados.",
                iconName: "doc.text.fill",
                accentColor: "amber",
                rootPaths: [
                    home.appendingPathComponent("Library/Logs"),
                    home.appendingPathComponent("Library/Logs/DiagnosticReports")
                ]
            ),
            JunkCategory(
                id: "trash",
                name: "Papelera de Reciclaje",
                subtitle: "Archivos eliminados que siguen ocupando espacio en el disco.",
                iconName: "trash.fill",
                accentColor: "rose",
                rootPaths: [home.appendingPathComponent(".Trash")]
            )
        ]
    }
    
    public func scanAll() async {
        isScanning = true
        var updatedCategories: [JunkCategory] = []
        var grandTotal: Int64 = 0
        
        for category in categories {
            var cat = category
            var catSize: Int64 = 0
            var catFiles: Int = 0
            var subItems: [JunkSubItem] = []
            
            for path in cat.rootPaths {
                guard fileManager.fileExists(atPath: path.path) else { continue }
                currentScanningPath = path.lastPathComponent
                
                // If directory has many child subfolders
                if path.lastPathComponent == "Caches" || path.lastPathComponent == "C" || path.lastPathComponent == ".npm" {
                    if let children = try? fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil) {
                        for child in children {
                            let (childSize, childCount) = calculateDirectorySize(at: child)
                            if childSize > 50_000 {
                                subItems.append(JunkSubItem(
                                    id: child.path,
                                    name: child.lastPathComponent,
                                    path: child,
                                    sizeBytes: childSize
                                ))
                                catSize += childSize
                                catFiles += childCount
                            }
                        }
                    }
                } else {
                    let (size, count) = calculateDirectorySize(at: path)
                    if size > 0 {
                        subItems.append(JunkSubItem(
                            id: path.path,
                            name: path.lastPathComponent,
                            path: path,
                            sizeBytes: size
                        ))
                        catSize += size
                        catFiles += count
                    }
                }
            }
            
            subItems.sort { $0.sizeBytes > $1.sizeBytes }
            cat.sizeBytes = catSize
            cat.itemCount = catFiles
            cat.subItems = subItems
            grandTotal += catSize
            updatedCategories.append(cat)
        }
        
        self.categories = updatedCategories
        self.totalFoundBytes = grandTotal
        self.lastScanDate = Date()
        self.isScanning = false
        self.currentScanningPath = ""
    }
    
    public func cleanAll() async {
        isCleaning = true
        var cleaned: Int64 = 0
        
        for i in 0..<categories.count {
            if categories[i].isSelected {
                for item in categories[i].subItems where item.isSelected {
                    let (itemSize, _) = calculateDirectorySize(at: item.path)
                    var isDir: ObjCBool = false
                    if fileManager.fileExists(atPath: item.path.path, isDirectory: &isDir) {
                        if isDir.boolValue {
                            if let inner = try? fileManager.contentsOfDirectory(at: item.path, includingPropertiesForKeys: nil) {
                                for sub in inner {
                                    try? fileManager.removeItem(at: sub)
                                }
                            }
                        } else {
                            try? fileManager.removeItem(at: item.path)
                        }
                        cleaned += itemSize
                    }
                }
            }
        }
        
        self.totalCleanedSessionBytes += cleaned
        self.isCleaning = false
        await scanAll()
    }
    
    private func calculateDirectorySize(at url: URL) -> (Int64, Int) {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return (0, 0) }
        
        if !isDir.boolValue {
            let attrs = try? fileManager.attributesOfItem(atPath: url.path)
            let s = (attrs?[.size] as? Int64) ?? 0
            return (s, 1)
        }
        
        var totalSize: Int64 = 0
        var totalFiles: Int = 0
        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return (0, 0)
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)) else { continue }
            if resourceValues.isDirectory == false {
                totalSize += Int64(resourceValues.fileSize ?? 0)
                totalFiles += 1
            }
        }
        
        return (totalSize, totalFiles)
    }
}
