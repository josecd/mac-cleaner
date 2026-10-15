import SwiftUI

public struct JunkCleanerView: View {
    @ObservedObject var junkService = JunkCleanerService.shared
    @State private var expandedCategoryId: String? = nil
    @State private var subItemSearchText: String = ""
    
    public init() {}
    
    var selectedBytes: Int64 {
        var total: Int64 = 0
        for cat in junkService.categories where cat.isSelected {
            for item in cat.subItems where item.isSelected {
                total += item.sizeBytes
            }
        }
        return total
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Archivos Basura")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Elimina elementos innecesarios. Toca cualquier categoría para ver su desglose.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                PrimaryGradientButton(
                    title: junkService.isCleaning ? "Limpiando..." : "Limpiar Seleccionados (\(Formatting.bytes(selectedBytes)))",
                    icon: "trash.fill",
                    isLoading: junkService.isCleaning
                ) {
                    Task {
                        await junkService.cleanAll()
                    }
                }
                .disabled(selectedBytes == 0 || junkService.isCleaning)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // List of Categories
            ScrollView {
                VStack(spacing: 14) {
                    ForEach($junkService.categories) { $cat in
                        GlassCard {
                            VStack(spacing: 12) {
                                // Category Header Row
                                HStack(spacing: 16) {
                                    Toggle("", isOn: $cat.isSelected)
                                        .labelsHidden()
                                        .toggleStyle(.checkbox)
                                        .onChange(of: cat.isSelected) { newValue in
                                            for i in 0..<cat.subItems.count {
                                                cat.subItems[i].isSelected = newValue
                                            }
                                        }
                                    
                                    ZStack {
                                        Circle()
                                            .fill(Color.purple.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: cat.iconName)
                                            .font(.title3)
                                            .foregroundColor(.purple)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(cat.name)
                                            .font(.headline)
                                        Text(cat.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(Formatting.bytes(cat.sizeBytes))
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Text("\(cat.subItems.count) elementos")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Expand Button
                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            expandedCategoryId = (expandedCategoryId == cat.id ? nil : cat.id)
                                        }
                                    }) {
                                        Image(systemName: expandedCategoryId == cat.id ? "chevron.up.circle.fill" : "chevron.down.circle")
                                            .font(.title3)
                                            .foregroundColor(.purple)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Expanded Sub-Items List (Granular Drill-Down)
                                if expandedCategoryId == cat.id {
                                    VStack(spacing: 10) {
                                        Divider()
                                        
                                        HStack {
                                            Text("Desglose detallado (\(cat.subItems.count) carpetas):")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Button("Marcar todos") {
                                                for i in 0..<cat.subItems.count { cat.subItems[i].isSelected = true }
                                            }
                                            .font(.caption2)
                                            .buttonStyle(.link)
                                            
                                            Button("Desmarcar todos") {
                                                for i in 0..<cat.subItems.count { cat.subItems[i].isSelected = false }
                                            }
                                            .font(.caption2)
                                            .buttonStyle(.link)
                                        }
                                        
                                        if cat.subItems.isEmpty {
                                            Text("No hay elementos individuales para mostrar.")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.vertical, 8)
                                        } else {
                                            VStack(spacing: 6) {
                                                ForEach($cat.subItems) { $item in
                                                    HStack(spacing: 12) {
                                                        Toggle("", isOn: $item.isSelected)
                                                            .labelsHidden()
                                                            .toggleStyle(.checkbox)
                                                        
                                                        Image(systemName: "folder.fill")
                                                            .foregroundColor(.purple.opacity(0.8))
                                                            .font(.caption)
                                                        
                                                        VStack(alignment: .leading, spacing: 1) {
                                                            Text(item.name)
                                                                .font(.system(size: 12, weight: .medium))
                                                            Text(item.path.path)
                                                                .font(.system(size: 10, design: .monospaced))
                                                                .foregroundColor(.secondary)
                                                                .lineLimit(1)
                                                                .truncationMode(.middle)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Text(Formatting.bytes(item.sizeBytes))
                                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                            .foregroundColor(.primary)
                                                    }
                                                    .padding(8)
                                                    .background(Color.white.opacity(0.04))
                                                    .cornerRadius(6)
                                                }
                                            }
                                            .frame(maxHeight: 280)
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .task {
            if junkService.totalFoundBytes == 0 {
                await junkService.scanAll()
            }
        }
    }
}
