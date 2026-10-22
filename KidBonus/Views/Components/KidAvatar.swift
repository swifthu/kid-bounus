import SwiftUI

struct KidAvatar: View {
    let name: String
    let size: CGFloat
    let colorHex: String

    @Environment(\.colorScheme) private var scheme

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return String(trimmed.suffix(2))
    }

    private func resolveColor(_ hex: String) -> Color {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard let v = UInt32(s, radix: 16) else { return .kami.accent }
        // 深色底上原本的深色字看不清，往白色方向提亮一档
        if scheme == .dark { return Color(hex: lighten(v)) }
        return Color(hex: v)
    }

    /// 往白色方向混 45%，深色字在深色底上才看得清。
    private func lighten(_ v: UInt32) -> UInt32 {
        func mix(_ c: Double) -> UInt32 { UInt32(c + (255 - c) * 0.45) }
        let r = mix(Double((v >> 16) & 0xFF))
        let g = mix(Double((v >> 8) & 0xFF))
        let b = mix(Double(v & 0xFF))
        return (r << 16) | (g << 8) | b
    }

    var body: some View {
        Text(initials)
            .font(.kamiFixed(.body, size: size * 0.36))
            .foregroundStyle(resolveColor(colorHex))
            .frame(width: size, height: size)
            .background(Color.kami.tagBgSoft)
            .clipShape(Circle())
    }
}
