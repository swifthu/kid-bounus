import SwiftUI

struct KidAvatar: View {
    let name: String
    let size: CGFloat
    let colorHex: String

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return String(trimmed.suffix(2))
    }

    private func resolveColor(_ hex: String) -> Color {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard let v = UInt32(s, radix: 16) else { return .kami.accent }
        return Color(hex: v)
    }

    var body: some View {
        Text(initials)
            .font(.kami(.body, size: size * 0.36))
            .foregroundStyle(resolveColor(colorHex))
            .frame(width: size, height: size)
            .background(Color.kami.tagBgSoft)
            .clipShape(Circle())
    }
}
