import SwiftUI

public enum NavigationSection: String, CaseIterable, Identifiable {
    case smartCare = "Cuidado Inteligente"
    case junkCleaner = "Archivos Basura"
    case uninstaller = "Desinstalador"
    case largeFiles = "Archivos Grandes"
    case systemMonitor = "Monitor del Sistema"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .smartCare: return "sparkles"
        case .junkCleaner: return "trash.fill"
        case .uninstaller: return "square.grid.2x2.fill"
        case .largeFiles: return "doc.badge.gearshape.fill"
        case .systemMonitor: return "gauge.with.needle.fill"
        }
    }
}

public struct MainWindowView: View {
    @State private var selectedSection: NavigationSection = .smartCare
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 6) {
                // App Branding Header
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.15, green: 0.45, blue: 1.0), Color(red: 0.05, green: 0.15, blue: 0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Zafiro Clean")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Elegancia y Rendimiento")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                Divider()
                    .padding(.bottom, 8)
                
                // Navigation Items
                ForEach(NavigationSection.allCases) { section in
                    Button(action: {
                        selectedSection = section
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: section.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedSection == section ? .white : .secondary)
                                .frame(width: 20)
                            
                            Text(section.rawValue)
                                .font(.system(size: 13, weight: selectedSection == section ? .semibold : .regular))
                                .foregroundColor(selectedSection == section ? .white : .primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedSection == section
                            ? RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.indigo.opacity(0.8), Color.purple.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            : nil
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                }
                
                Spacer()
                
                // Footer
                HStack {
                    Image(systemName: "shield.checkerboard")
                        .foregroundColor(.green)
                    Text("Protegido y Seguro")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(16)
            }
            .frame(minWidth: 210, maxWidth: 230)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        } detail: {
            Group {
                switch selectedSection {
                case .smartCare:
                    SmartCareView()
                case .junkCleaner:
                    JunkCleanerView()
                case .uninstaller:
                    AppUninstallerView()
                case .largeFiles:
                    LargeFilesView()
                case .systemMonitor:
                    SystemMonitorDetailView()
                }
            }
            .frame(minWidth: 700, minHeight: 560)
            .background(Color(nsColor: .underPageBackgroundColor).opacity(0.3))
        }
    }
}
