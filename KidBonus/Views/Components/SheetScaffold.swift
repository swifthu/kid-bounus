import SwiftUI

struct SheetScaffold<Content: View>: View {
    let title: String
    let message: String?
    let actions: [SheetAction]
    let content: () -> Content

    init(title: String, message: String? = nil,
         actions: [SheetAction] = [],
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.message = message
        self.actions = actions
        self.content = content
    }

    var body: some View {
        VStack(spacing: Spacing.s3) {
            Capsule()
                .fill(Color.kami.border)
                .frame(width: 36, height: 4)
                .padding(.top, Spacing.s1)

            Text(title).font(.kami(.body, size: 17))

            if let m = message {
                Text(m).font(.kami(.body, size: 13))
                    .foregroundStyle(Color.kami.muted)
            }

            content()

            HStack(spacing: Spacing.s2) {
                ForEach(actions) { a in
                    KamiButton(a.title, style: a.primary ? .primary : .secondary) {
                        a.handler()
                    }
                }
            }
        }
        .padding(Spacing.s4)
        .background(Color.kami.bg)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

struct SheetAction: Identifiable {
    let id = UUID()
    let title: String
    let primary: Bool
    let handler: () -> Void
}
