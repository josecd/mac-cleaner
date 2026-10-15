import SwiftUI

public struct SmartCareView: View {
    @ObservedObject var junkService = JunkCleanerService.shared
    @ObservedObject var monitor = SystemMonitor.shared
    
    @State private var isRotating = false
    @State private var hasScanned = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Hero Icon / Glowing Ring
            ZStack {
                // Background Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 130
                        )
                    )
                    .frame(width: 250, height: 250)
                
                // Outer animated ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .indigo, .pink, .purple],
                            center: .center
                        ),
                        lineWidth: 4.5
                    )
                    .frame(width: 175, height: 175)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(
                        isRotating ? Animation.linear(duration: 4).repeatForever(autoreverses: false) : .default,
                        value: isRotating
                    )
                
                // Inner button
                Button(action: {
                    Task {
                        isRotating = true
                        await junkService.scanAll()
                        isRotating = false
                        hasScanned = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.indigo.opacity(0.85), Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 144, height: 144)
                            .shadow(color: .purple.opacity(0.5), radius: 16, x: 0, y: 8)
                        
                        VStack(spacing: 6) {
                            Image(systemName: hasScanned ? "checkmark.circle.fill" : "sparkles")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(.white)
                            Text(hasScanned ? "Escanear" : "Analizar")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(junkService.isScanning)
            }
            
            // Status and Summary
            VStack(spacing: 8) {
                if junkService.isScanning {
                    Text("Analizando el sistema...")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(junkService.currentScanningPath.isEmpty
                         ? "Buscando cachés huérfanas, logs y restos..."
                         : "Revisando: \(junkService.currentScanningPath)...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if hasScanned {
                    Text("Análisis completado")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Se encontraron \(Formatting.bytes(junkService.totalFoundBytes)) de archivos innecesarios")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Cuidado Inteligente")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Analiza tu Mac en busca de archivos basura y optimizaciones")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Clean Action if scanned
            if hasScanned && junkService.totalFoundBytes > 0 {
                PrimaryGradientButton(
                    title: junkService.isCleaning ? "Limpiando sistema..." : "Ejecutar Limpieza (\(Formatting.bytes(junkService.totalFoundBytes)))",
                    icon: "wand.and.stars",
                    isLoading: junkService.isCleaning
                ) {
                    Task {
                        await junkService.cleanAll()
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if junkService.totalFoundBytes == 0 {
                await junkService.scanAll()
                hasScanned = true
            }
        }
    }
}
