import SwiftUI

struct KidTabs: View {
    let kids: [Kid]
    @Binding var selected: UUID

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(kids) { kid in
                tabButton(for: kid)
            }
        }
        .padding(Spacing.s1)
        .background(Color.kami.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.kami.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func tabButton(for kid: Kid) -> some View {
        let isSelected = selected == kid.id
        Button {
            selected = kid.id
        } label: {
            HStack(spacing: Spacing.s2) {
                KidAvatar(name: kid.name, size: 26, colorHex: kid.colorHex)
                Text(kid.name).font(.kami(.body, size: 14))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isSelected ? Color.kami.bg : Color.clear)
            .foregroundStyle(isSelected ? Color.kami.accent : Color.kami.muted)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .stroke(Color.kami.accent, lineWidth: isSelected ? 1 : 0)
            )
        }
        .buttonStyle(.kamiPress)
    }
}
