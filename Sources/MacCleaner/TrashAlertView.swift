import SwiftUI
import AppKit

public struct TrashAlertView: View {
    public let item: TrashedAppItem
    @ObservedObject var watcher = TrashWatcherService.shared
    
    public init(item: TrashedAppItem) {
        self.item = item
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Puntero / Notch superior hacia la barra de menú
            HStack {
                Spacer()
                CalloutTriangle()
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.92))
                    .frame(width: 20, height: 10)
                    .padding(.trailing, 40)
            }
            .padding(.bottom, -1)
            
            // Cuerpo de la tarjeta con efecto glassmorphism
            VStack(alignment: .leading, spacing: 14) {
                // 1. Título y subtítulo
                VStack(alignment: .leading, spacing: 4) {
                    Text("Desinstalar las aplicaciones correctamente")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Elimina aplicaciones borradas junto con todos sus restos.")
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // 2. Fila con el ícono y nombre de la app
                HStack(spacing: 12) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if item.leftoversSizeBytes > 0 {
                            Text("\(Formatting.bytes(item.leftoversSizeBytes)) en archivos residuales")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 0.15, green: 0.45, blue: 1.0))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
                
                // 3. Botones de acción
                HStack(spacing: 12) {
                    Button(action: {
                        watcher.ignoreAlert()
                    }) {
                        Text("Ignorar")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Color.primary.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        Task {
                            await watcher.uninstallWithLeftovers()
                        }
                    }) {
                        HStack(spacing: 6) {
                            if watcher.isCleaning {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .colorInvert()
                            } else if watcher.cleanSuccess {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                Text("¡Limpio!")
                            } else {
                                Text("Desinstalar...")
                            }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.76, green: 0.24, blue: 0.62),
                                    Color(red: 0.58, green: 0.18, blue: 0.52)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .shadow(color: Color(red: 0.70, green: 0.20, blue: 0.55).opacity(0.35), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(watcher.isCleaning)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.92))
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.20), radius: 16, x: 0, y: 8)
            )
        }
        .frame(width: 340)
        .padding(8)
    }
}

struct CalloutTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
