import SwiftUI

enum TagKind { case `default`, faint, success, danger, warn }

struct Tag: View {
    let text: String
    let kind: TagKind

    var body: some View {
        Text(text)
            .font(.kami(.body, size: 11))
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, 4)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
    }

    private var foreground: Color {
        switch kind {
        case .success: return .kami.success
        case .danger:  return .kami.danger
        case .warn:    return .kami.warn
        case .faint:   return .kami.muted
        default:       return .kami.accent
        }
    }

    private var background: Color {
        switch kind {
        case .success: return Color.kami.successBg
        case .danger:  return Color.kami.dangerBg
        case .warn:    return Color.kami.warnBg
        case .faint:   return .kami.tagBgFaint
        default:       return .kami.tagBgSoft
        }
    }
}
