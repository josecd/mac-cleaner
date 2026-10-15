import SwiftUI

public struct SystemMonitorDetailView: View {
    @ObservedObject var monitor = SystemMonitor.shared
    @ObservedObject var processMonitor = ProcessMonitorService.shared
    @State private var isPurging: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monitor del Sistema")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Monitoreo en tiempo real de recursos y rendimiento.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    PrimaryGradientButton(
                        title: isPurging ? "Optimizando..." : "Liberar Memoria RAM",
                        icon: "bolt.fill",
                        isLoading: isPurging
                    ) {
                        isPurging = true
                        monitor.purgeMemory()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isPurging = false
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Top Metrics Grid (3 Big Rings)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    GlassCard {
                        VStack(spacing: 12) {
                            MetricRingView(
                                percent: monitor.stats.ramUsagePercent,
                                title: "Memoria RAM",
                                value: String(format: "%.1f%% en uso", monitor.stats.ramUsagePercent),
                                gradient: [.blue, .purple],
                                ringSize: 90
                            )
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Usada:").foregroundColor(.secondary).font(.caption)
                                    Spacer()
                                    Text(Formatting.bytes(monitor.stats.usedRamBytes)).font(.caption).fontWeight(.medium)
                                }
                                HStack {
                                    Text("Libre:").foregroundColor(.secondary).font(.caption)
                                    Spacer()
                                    Text(Formatting.bytes(monitor.stats.freeRamBytes)).font(.caption).fontWeight(.medium)
                                }
                                HStack {
                                    Text("Total:").foregroundColor(.secondary).font(.caption)
                                    Spacer()
                                    Text(Formatting.bytes(monitor.stats.totalRamBytes)).font(.caption).fontWeight(.medium)
                                }
                            }
                        }
                    }
                    
                    GlassCard {
                        VStack(spacing: 12) {
                            MetricRingView(
                                percent: monitor.stats.cpuUsagePercent,
                                title: "Procesador (CPU)",
                                value: String(format: "%.1f%%", monitor.stats.cpuUsagePercent),
                                gradient: [.orange, .red],
                                ringSize: 90
                            )
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Carga:").foregroundColor(.secondary).font(.caption)
                                    Spacer()
                                    Text(String(format: "%.1f%%", monitor.stats.cpuUsagePercent)).font(.caption).fontWeight(.medium)
                                }
                                HStack {
                                    Text("Estado:").foregroundColor(.secondary).font(.caption)
                                    Spacer()
                                    Text(monitor.stats.cpuUsagePercent > 80 ? "Alto" : "Normal").font(.caption).fontWeight(.medium)
                                }
                            }
                        }
                    }
                    
                    GlassCard {
                        VStack(spacing: 12) {
                            MetricRingView(
                                percent: monitor.stats.diskUsagePercent,
                                title: "Almacenamiento",
                                value: String(format: "%.0f%% ocupado", monitor.stats.diskUsagePercent),
                                gradient: [.teal, .green],
                                ringSize: 90
                            )
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Libre:").foregroundColor(.secondary).font(.caption)
                                    Spacer()
                                    Text(Formatting.bytes(monitor.stats.freeDiskBytes)).font(.caption).fontWeight(.medium)
                                }
                                HStack {
                                    Text("Usado:").foregroundColor(.secondary).font(.caption)
                                    Spacer()
                                    Text(Formatting.bytes(monitor.stats.usedDiskBytes)).font(.caption).fontWeight(.medium)
                                }
                                HStack {
                                    Text("Capacidad:").foregroundColor(.secondary).font(.caption)
                                    Spacer()
                                    Text(Formatting.bytes(monitor.stats.totalDiskBytes)).font(.caption).fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Heavy Apps Consumption Section (Live Processes)
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("Aplicaciones con Mayor Consumo de Memoria")
                                .font(.headline)
                            Spacer()
                            Text("En vivo")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(processMonitor.heavyApps) { app in
                                HStack(spacing: 12) {
                                    Image(nsImage: app.icon)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    Text(app.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(Formatting.bytes(app.memoryBytes))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    Button("Salir") {
                                        processMonitor.quitApp(app)
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                    Button("Forzar") {
                                        processMonitor.forceQuitApp(app)
                                    }
                                    .font(.caption)
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                }
                                .padding(8)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Battery Card if present
                if monitor.stats.hasBattery {
                    GlassCard {
                        HStack(spacing: 20) {
                            Image(systemName: monitor.stats.isCharging ? "battery.100.bolt" : "battery.100")
                                .font(.system(size: 38))
                                .foregroundColor(monitor.stats.isCharging ? .green : .blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Batería de la Mac")
                                    .font(.headline)
                                Text(monitor.stats.isCharging ? "Conectado al adaptador de corriente" : "Operando con batería")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(monitor.stats.batteryPercent)%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
    }
}
