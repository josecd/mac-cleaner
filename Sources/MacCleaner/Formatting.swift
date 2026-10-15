import Foundation

public enum Formatting {
    public static func bytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    public static func bytes(_ bytes: UInt64) -> String {
        return self.bytes(Int64(bytes))
    }
}
