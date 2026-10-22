import SwiftUI

/// 图标选择器：从预设图标里挑一个。
/// 预设表在 IconPreset 里，只收确实存在的 SF Symbol，避免出现空白方块。
/// 网格用普通行拼而不是 LazyVGrid，这样它能跟着外层滚动区一起滚，不产生嵌套滚动。
struct IconPicker: View {
    @Binding var selection: String

    private let perRow = 6

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("图标")
                .font(.kami(.body, size: 12))
                .foregroundStyle(Color.kami.meta)
            VStack(spacing: Spacing.s2) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: Spacing.s2) {
                        ForEach(row, id: \.self) { name in
                            cell(name)
                        }
                    }
                }
            }
        }
    }

    private var rows: [[String]] {
        stride(from: 0, to: IconPreset.all.count, by: perRow).map { start in
            Array(IconPreset.all[start..<min(start + perRow, IconPreset.all.count)])
        }
    }

    private func cell(_ name: String) -> some View {
        Button { selection = name } label: {
            Image(systemName: name)
                .font(.system(size: 18))
                .foregroundStyle(selection == name ? Color.kami.accent : Color.kami.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(selection == name ? Color.kami.tagBgSoft : Color.kami.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .stroke(selection == name ? Color.kami.accent : Color.kami.border,
                                lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("icon.\(name)")
    }
}
