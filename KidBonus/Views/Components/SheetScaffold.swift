import SwiftUI

struct SheetScaffold<Content: View>: View {
    let title: String
    let message: String?
    let actions: [SheetAction]
    /// 表单里塞了图标网格这类大内容时，用 .large 打开才有地方摆
    let detents: Set<PresentationDetent>
    let content: () -> Content

    init(title: String, message: String? = nil,
         actions: [SheetAction] = [],
         detents: Set<PresentationDetent> = [.medium, .large],
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.message = message
        self.actions = actions
        self.detents = detents
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

            // 内容放在滚动区里：图标选择器有几十个图标，字号放大后表单也会变高，
            // 固定高度会把它挤出屏幕。标题和按钮留在滚动区外，始终可见。
            ScrollView {
                VStack(spacing: Spacing.s3) {
                    content()
                }
            }
            .scrollDismissesKeyboard(.interactively)

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
        // 系统 sheet 本身是半透明材质，内容不满一屏时下方会透出父页面，
        // 看起来像透明窗口和纯色窗口叠在一起。这里把整块弹层都刷成实色。
        .presentationBackground(Color.kami.bg)
        .presentationDetents(detents)
        .presentationDragIndicator(.hidden)
    }
}

struct SheetAction: Identifiable {
    let id = UUID()
    let title: String
    let primary: Bool
    let handler: () -> Void
}
