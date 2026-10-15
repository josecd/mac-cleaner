import SwiftUI
import AppKit

public struct AppUninstallerView: View {
    @ObservedObject var uninstaller = AppUninstallerService.shared
    @State private var searchText = ""
    @State private var selectedApp: InstalledApp?
    @State private var showConfirm: Bool = false
    @State private var expandedAppId: String? = nil
    
    public init() {}
    
    var filteredApps: [InstalledApp] {
        if searchText.isEmpty {
            return uninstaller.apps
        } else {
            return uninstaller.apps.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.id.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Desinstalador de Apps")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Elimina aplicaciones y sus carpetas huérfanas en Library por completo.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                PrimaryGradientButton(
                    title: "Recargar",
                    icon: "arrow.clockwise",
                    isLoading: uninstaller.isScanning
                ) {
                    Task {
                        await uninstaller.scanApps()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Buscar aplicación...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.08))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // List of Apps
            if uninstaller.isScanning && uninstaller.apps.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                    Text("Buscando aplicaciones y restos...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredApps) { app in
                            GlassCard {
                                VStack(spacing: 10) {
                                    HStack(spacing: 14) {
                                        // App Icon
                                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.bundleUrl.path))
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(app.name)
                                                .font(.headline)
                                            HStack(spacing: 8) {
                                                Text("v\(app.version)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                if !app.leftoverPaths.isEmpty {
                                                    Text("• \(app.leftoverPaths.count) restos asociados")
                                                        .font(.caption2)
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(Formatting.bytes(app.totalSizeBytes))
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                            if app.leftoversSizeBytes > 0 {
                                                Text("App: \(Formatting.bytes(app.appSizeBytes)) + Restos: \(Formatting.bytes(app.leftoversSizeBytes))")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Button(action: {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                expandedAppId = (expandedAppId == app.id ? nil : app.id)
                                            }
                                        }) {
                                            Image(systemName: expandedAppId == app.id ? "chevron.up.circle.fill" : "chevron.down.circle")
                                                .font(.title3)
                                                .foregroundColor(.purple)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Ver carpetas asociadas")
                                        
                                        Button(action: {
                                            selectedApp = app
                                            showConfirm = true
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red.opacity(0.8))
                                                .padding(8)
                                                .background(Color.red.opacity(0.1))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .help("Desinstalar completamente")
                                    }
                                    
                                    // Expanded Leftovers Tree
                                    if expandedAppId == app.id {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Divider()
                                            Text("Ubicación del binario:")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.secondary)
                                            Text(app.bundleUrl.path)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(.primary)
                                            
                                            if !app.leftoverPaths.isEmpty {
                                                Text("Carpetas residuales detectadas:")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.orange)
                                                    .padding(.top, 4)
                                                ForEach(app.leftoverPaths, id: \.self) { path in
                                                    Text("↳ \(path.path)")
                                                        .font(.system(size: 10, design: .monospaced))
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                        .truncationMode(.middle)
                                                }
                                            } else {
                                                Text("No se detectaron carpetas huérfanas en Library.")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(.bottom, 4)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .confirmationDialog(
            "¿Desinstalar \(selectedApp?.name ?? "")?",
            isPresented: $showConfirm,
            actions: {
                Button("Mover a la papelera con todos sus restos", role: .destructive) {
                    if let app = selectedApp {
                        Task {
                            await uninstaller.uninstall(app: app)
                        }
                    }
                }
                Button("Cancelar", role: .cancel) {}
            },
            message: {
                Text("Se eliminará la aplicación y todos sus archivos asociados en Application Support, Caches y Preferences.")
            }
        )
        .task {
            if uninstaller.apps.isEmpty {
                await uninstaller.scanApps()
            }
        }
    }
}
