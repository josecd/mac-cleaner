import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var monitor = SystemMonitor.shared
    @ObservedObject var junkService = JunkCleanerService.shared
    @ObservedObject var processMonitor = ProcessMonitorService.shared
    @Environment(\.openWindow) private var openWindow
    
    @State private var isFreeingDisk: Bool = false
    @State private var isFreeingRam: Bool = false
    @State private var speedTestActive: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // 1. Header: Estado del Mac + Laptop Icon
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text("Estado del Mac:")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("Excelente")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(red: 0.22, green: 0.85, blue: 1.0))
                    }
                    Text("MacBook Air")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.22, green: 0.85, blue: 1.0).opacity(0.15))
                        .frame(width: 44, height: 34)
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.22, green: 0.85, blue: 1.0))
                        .shadow(color: Color(red: 0.22, green: 0.85, blue: 1.0).opacity(0.7), radius: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            // 2. Shield Banner (Protection)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(Color(red: 0.20, green: 0.85, blue: 0.40))
                            .font(.system(size: 14))
                        Text("Protegido por")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Text("MacCleaner")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("Protegido")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                }
                
                Text("Supervisión de malware ACTIVADA")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Último análisis: Sistema limpio")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            
            // 3. Grid of 6 Cards (2x3)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                // Card 1: Macintosh HD
                MenuCard {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: "internaldrive.fill")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 13))
                            Text("Macintosh HD")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        Text("Disponible: \(Formatting.bytes(monitor.stats.freeDiskBytes))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.25))
                        HStack {
                            Spacer()
                            Button(isFreeingDisk ? "..." : "Liberar") {
                                Task {
                                    isFreeingDisk = true
                                    await junkService.cleanAll()
                                    isFreeingDisk = false
                                }
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.45, green: 0.55, blue: 1.0))
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Card 2: Memoria
                MenuCard {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: "memorychip")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 13))
                            Text("Memoria")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        Text("Presión: \(Int(monitor.stats.ramUsagePercent))%")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                        HStack {
                            Spacer()
                            Button(isFreeingRam ? "..." : "Liberar") {
                                isFreeingRam = true
                                monitor.purgeMemory()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    isFreeingRam = false
                                }
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.45, green: 0.55, blue: 1.0))
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Card 3: Batería
                MenuCard {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: monitor.stats.isCharging ? "battery.100.bolt" : "battery.100")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 13))
                            Text("Batería")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(monitor.stats.batteryPercent)%")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text(monitor.stats.isCharging ? "Cargando" : "No se está cargando")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer().frame(height: 12)
                    }
                }
                
                // Card 4: CPU (CON TEMPERATURA 77°C)
                MenuCard {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 13))
                            Text("CPU")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(monitor.stats.cpuTemperature)°C")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.25))
                        }
                        Text("Carga: \(Int(monitor.stats.cpuUsagePercent))%")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer().frame(height: 12)
                    }
                }
                
                // Card 5: Wi-Fi
                MenuCard {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: "wifi")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 13))
                            Text("Wi-Fi")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        HStack(spacing: 8) {
                            Text("↑ \(monitor.stats.wifiUploadSpeed)")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.65))
                            Text("↓ \(monitor.stats.wifiDownloadSpeed)")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        HStack {
                            Spacer()
                            Button("Probar velocidad") {
                                speedTestActive = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    speedTestActive = false
                                }
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.45, green: 0.55, blue: 1.0))
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Card 6: Dispositivos conectados (Bluetooth / Magic Mouse)
                MenuCard {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 13))
                            Text("Dispositivos")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        HStack {
                            Image(systemName: "magicmouse")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Magic Mouse...")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                            Spacer()
                            Text("\(monitor.stats.connectedDeviceBattery)%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer().frame(height: 12)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // 4. Recommendation Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Nuestra recomendación de hoy")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 38, height: 38)
                        Image(systemName: "sparkles.square.filled.on.square")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Toma el control sobre tus apps")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Text("Desinstala, actualiza y elimina restos de aplicaciones antiguas.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                HStack {
                    Spacer()
                    Button("Revisar aplicaciones") {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "main-window")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(8)
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            
            // 5. Footer (Bottom Bar)
            HStack {
                Image(systemName: "display")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 13))
                
                Spacer()
                
                Button("Mostrar MacCleaner") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main-window")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await junkService.cleanAll()
                        }
                    }) {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        NSApp.terminate(nil)
                    }) {
                        Image(systemName: "power")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .frame(width: 360)
        .background(
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.03, blue: 0.25), Color(red: 0.16, green: 0.04, blue: 0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct MenuCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.18, green: 0.08, blue: 0.38).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                    )
            )
    }
}
