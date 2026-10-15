import AppKit
import Foundation
import Darwin

public struct AppMemoryUsage: Identifiable {
    public let id: pid_t
    public let name: String
    public let app: NSRunningApplication?
    public let icon: NSImage
    public var memoryBytes: Int64
    public var memoryMB: Double {
        Double(memoryBytes) / (1024.0 * 1024.0)
    }
}

@MainActor
public final class ProcessMonitorService: ObservableObject {
    public static let shared = ProcessMonitorService()
    
    @Published public var heavyApps: [AppMemoryUsage] = []
    @Published public var isHighMemoryAlert: Bool = false
    
    private var timer: Timer?
    
    public init() {
        refresh()
        startMonitoring()
    }
    
    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }
    
    public func refresh() {
        var appList: [AppMemoryUsage] = []
        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        
        for app in runningApps {
            let pid = app.processIdentifier
            var info = proc_taskinfo()
            let size = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(MemoryLayout<proc_taskinfo>.size))
            
            if size == MemoryLayout<proc_taskinfo>.size {
                let residentBytes = Int64(info.pti_resident_size)
                let icon = app.icon ?? NSWorkspace.shared.icon(for: .application)
                let name = app.localizedName ?? "App"
                
                appList.append(AppMemoryUsage(
                    id: pid,
                    name: name,
                    app: app,
                    icon: icon,
                    memoryBytes: residentBytes
                ))
            }
        }
        
        // Sort from heaviest to lightest
        appList.sort { $0.memoryBytes > $1.memoryBytes }
        self.heavyApps = Array(appList.prefix(6))
        
        // Alert trigger: if RAM usage > 75% or top app > 1.5GB
        let topConsumer = appList.first?.memoryBytes ?? 0
        if topConsumer > 1_500_000_000 || SystemMonitor.shared.stats.ramUsagePercent > 75 {
            self.isHighMemoryAlert = true
        } else {
            self.isHighMemoryAlert = false
        }
    }
    
    public func quitApp(_ item: AppMemoryUsage) {
        item.app?.terminate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refresh()
        }
    }
    
    public func forceQuitApp(_ item: AppMemoryUsage) {
        item.app?.forceTerminate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refresh()
        }
    }
    
    public func forceQuitAllHeavy() {
        for app in heavyApps.prefix(3) {
            app.app?.terminate()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.refresh()
        }
    }
}
