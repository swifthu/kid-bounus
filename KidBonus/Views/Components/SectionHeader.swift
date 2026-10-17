import SwiftUI

struct SectionHeader: View {
    let num: String?
    let label: String

    var body: some View {
        HStack {
            if let num, !num.isEmpty {
                Text(num)
                    .font(.kami(.body, size: 13))
                    .foregroundStyle(Color.kami.accent)
            }
            Text(label)
                .font(.kami(.body, size: 11))
                .foregroundStyle(Color.kami.meta)
        }
    }
}
