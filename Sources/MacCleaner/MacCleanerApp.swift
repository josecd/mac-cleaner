import SwiftUI

@main
struct MacCleanerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Ventana Principal de Zafiro Clean
        WindowGroup("Zafiro Clean", id: "main-window") {
            MainWindowView()
                .frame(minWidth: 860, minHeight: 560)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        
        // Menú en la Barra de Estado (Menu Bar Extra)
        MenuBarExtra("Zafiro Clean", systemImage: "sparkles") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}
