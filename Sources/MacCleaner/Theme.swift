import SwiftUI

public enum Theme {
    // Ultra-clean Obsidian & Dark Graphite Palette (Raycast / Linear style)
    public static let bgPrimary = Color(red: 0.05, green: 0.06, blue: 0.08)
    public static let bgSecondary = Color(red: 0.08, green: 0.09, blue: 0.12)
    public static let bgSidebar = Color(red: 0.06, green: 0.07, blue: 0.09)
    public static let bgCard = Color(red: 0.10, green: 0.11, blue: 0.15).opacity(0.85)
    public static let bgCardHover = Color(red: 0.13, green: 0.15, blue: 0.20)
    
    // Borders & Glass
    public static let borderSubtle = Color.white.opacity(0.08)
    public static let borderFocus = Color.white.opacity(0.18)
    
    // Accents
    public static let accentViolet = Color(red: 0.55, green: 0.35, blue: 0.95)
    public static let accentCyan = Color(red: 0.10, green: 0.75, blue: 0.95)
    public static let accentEmerald = Color(red: 0.15, green: 0.82, blue: 0.55)
    public static let accentAmber = Color(red: 0.95, green: 0.65, blue: 0.15)
    public static let accentRose = Color(red: 0.95, green: 0.25, blue: 0.45)
    
    // Typography
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.65)
    public static let textMuted = Color.white.opacity(0.40)
}
