import Foundation
import AppKit

public struct LargeFileItem: Identifiable {
    public let id: String
    public let name: String
    public let url: URL
    public let sizeBytes: Int64
    public let modificationDate: Date
    public let kind: String
    public var isSelected: Bool = false
}

@MainActor
public final class LargeFilesService: ObservableObject {
    public static let shared = LargeFilesService()
    
    @Published public var files: [LargeFileItem] = []
    @Published public var isScanning: Bool = false
    @Published public var totalSize: Int64 = 0
    
    private let fileManager = FileManager.default
    
    public init() {}
    
    public func scanLargeFiles(minSizeBytes: Int64 = 50_000_000) async { // > 50 MB
        isScanning = true
        var found: [LargeFileItem] = []
        let home = URL(fileURLWithPath: NSHomeDirectory())
        
        let searchFolders = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Movies"),
            home.appendingPathComponent("Desktop")
        ]
        
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey]
        
        for folder in searchFolders {
            guard fileManager.fileExists(atPath: folder.path) else { continue }
            guard let enumerator = fileManager.enumerator(
                at: folder,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }
            
            for case let fileURL as URL in enumerator {
                guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                      values.isDirectory == false,
                      let size = values.fileSize,
                      Int64(size) >= minSizeBytes else { continue }
                
                let ext = fileURL.pathExtension.lowercased()
                let kind: String
                if ["dmg", "pkg", "iso"].contains(ext) { kind = "Instalador" }
                else if ["mp4", "mov", "mkv", "avi"].contains(ext) { kind = "Video" }
                else if ["zip", "tar", "gz", "rar", "7z"].contains(ext) { kind = "Archivo" }
                else { kind = "Documento" }
                
                found.append(LargeFileItem(
                    id: fileURL.path,
                    name: fileURL.lastPathComponent,
                    url: fileURL,
                    sizeBytes: Int64(size),
                    modificationDate: values.contentModificationDate ?? Date(),
                    kind: kind
                ))
            }
        }
        
        found.sort { $0.sizeBytes > $1.sizeBytes }
        self.files = found
        self.totalSize = found.reduce(0) { $0 + $1.sizeBytes }
        self.isScanning = false
    }
    
    public func delete(item: LargeFileItem) {
        try? fileManager.trashItem(at: item.url, resultingItemURL: nil)
        files.removeAll { $0.id == item.id }
        self.totalSize = files.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public func revealInFinder(item: LargeFileItem) {
        NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: item.url.deletingLastPathComponent().path)
    }
}
