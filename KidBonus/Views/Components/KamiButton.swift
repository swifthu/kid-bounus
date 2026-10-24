import SwiftUI

enum KamiButtonStyle { case primary, secondary }

struct KamiButton: View {
    let title: String
    let systemImage: String?
    let style: KamiButtonStyle
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil,
         style: KamiButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s2) {
                if let s = systemImage {
                    Image(systemName: s)
                }
                Text(title)
            }
            .font(.kami(.body, size: 13))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.kamiPress)
    }

    private var background: Color {
        style == .primary ? .kami.accent : .kami.surfaceWarm
    }
    private var foreground: Color {
        style == .primary ? .kami.accentOn : .kami.fg2
    }
    private var borderColor: Color {
        style == .primary ? .kami.accent : .kami.border
    }
}
