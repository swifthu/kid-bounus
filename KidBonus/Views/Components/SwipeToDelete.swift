import SwiftUI

/// 左滑露出删除按钮。列表是 ScrollView + VStack 而不是 List，
/// 系统 swipeActions 在这里不生效，只能自己实现。
/// 按 iOS 常见习惯：向左滑，按钮从右边出来。
struct SwipeToDelete<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var isOpen = false
    @State private var x: CGFloat = 0
    private let buttonWidth: CGFloat = 84

    var body: some View {
        ZStack(alignment: .trailing) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.kami.bg)
                .offset(x: x)
                // simultaneousGesture：与外层 ScrollView 共存，竖向滑动仍能滚动
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { v in
                            let base = isOpen ? -buttonWidth : 0
                            x = min(max(base + v.translation.width, -buttonWidth), 0)
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                isOpen = x < -buttonWidth / 2
                                x = isOpen ? -buttonWidth : 0
                            }
                        }
                )

            // 只在展开时存在：收起时若按钮仍在，内容行会盖住它导致点不动
            if isOpen {
                Button {
                    withAnimation { isOpen = false; x = 0 }
                    onDelete()
                } label: {
                    Text("删除")
                        .font(.kami(.body, size: 14))
                        .foregroundStyle(Color.kami.danger)
                        .frame(width: buttonWidth)
                        .frame(maxHeight: .infinity)
                        .background(Color.kami.dangerBg)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
