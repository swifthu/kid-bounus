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
                // 内容行本身可能是按钮（比如「我的」页的积分项）。展开后它仍然占着
                // 整行的可点区域，会把右边露出来的删除按钮挡住，点不动。
                // 展开时关掉它的点击，删除按钮下面再铺一层「点一下收起」。
                .allowsHitTesting(!isOpen)
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
                // 铺在内容之上、删除按钮之下：点左边收起，点右边仍然是删除
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            isOpen = false
                            x = 0
                        }
                    }

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
                .buttonStyle(.kamiPress)
            }
        }
    }
}
