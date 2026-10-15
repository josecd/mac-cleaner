import SwiftUI

public struct LargeFilesView: View {
    @ObservedObject var largeFilesService = LargeFilesService.shared
    @State private var selectedKind: String = "Todos"
    
    public init() {}
    
    var filteredFiles: [LargeFileItem] {
        if selectedKind == "Todos" {
            return largeFilesService.files
        } else {
            return largeFilesService.files.filter { $0.kind == selectedKind }
        }
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Archivos Grandes y Antiguos")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Localiza archivos pesados (> 50 MB) olvidados en Descargas y Documentos.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                PrimaryGradientButton(
                    title: largeFilesService.isScanning ? "Buscando..." : "Escanear Archivos",
                    icon: "sparkle.magnifyingglass",
                    isLoading: largeFilesService.isScanning
                ) {
                    Task {
                        await largeFilesService.scanLargeFiles()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Filter Pills
            HStack(spacing: 8) {
                ForEach(["Todos", "Instalador", "Video", "Archivo", "Documento"], id: \.self) { kind in
                    Button(action: {
                        selectedKind = kind
                    }) {
                        Text(kind)
                            .font(.system(size: 12, weight: selectedKind == kind ? .bold : .medium))
                            .foregroundColor(selectedKind == kind ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedKind == kind
                                ? RoundedRectangle(cornerRadius: 8).fill(Color.purple)
                                : RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                if largeFilesService.totalSize > 0 {
                    Text("Total: \(Formatting.bytes(largeFilesService.totalSize))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal)
            
            // Files List
            if largeFilesService.isScanning && largeFilesService.files.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                    Text("Rastreando archivos pesados en el disco...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if filteredFiles.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                    Text("No se encontraron archivos grandes en esta categoría.")
                        .font(.headline)
                    Text("Pulsa 'Escanear Archivos' para iniciar una búsqueda.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredFiles) { file in
                            GlassCard {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.purple.opacity(0.15))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: iconForKind(file.kind))
                                            .font(.system(size: 16))
                                            .foregroundColor(.purple)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.name)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(file.url.path)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(Formatting.bytes(file.sizeBytes))
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Text(file.kind)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Button(action: {
                                        largeFilesService.revealInFinder(item: file)
                                    }) {
                                        Image(systemName: "folder")
                                            .foregroundColor(.secondary)
                                            .padding(6)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Mostrar en Finder")
                                    
                                    Button(action: {
                                        largeFilesService.delete(item: file)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red.opacity(0.8))
                                            .padding(6)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Mover a la papelera")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .task {
            if largeFilesService.files.isEmpty {
                await largeFilesService.scanLargeFiles()
            }
        }
    }
    
    func iconForKind(_ kind: String) -> String {
        switch kind {
        case "Instalador": return "opticaldisc.fill"
        case "Video": return "film.fill"
        case "Archivo": return "doc.zipper"
        default: return "doc.fill"
        }
    }
}
