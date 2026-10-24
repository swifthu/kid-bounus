import SwiftUI

@Observable
final class ToastCenter {
    /// toast 上的可选操作，比如「撤销」。
    struct Action: Equatable {
        let title: String
        let handler: () -> Void

        static func == (l: Action, r: Action) -> Bool { l.title == r.title }
    }

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let kind: Kind
        let title: String
        let body: String?
        let action: Action?
        enum Kind: Equatable { case info, success, danger }

        static func == (l: Toast, r: Toast) -> Bool { l.id == r.id }
    }
    var current: Toast?

    static let defaultDuration: TimeInterval = 2.4
    /// 带操作按钮的 toast 停留久一点，给用户点「撤销」的时间
    static let actionDuration: TimeInterval = 6

    @MainActor
    func show(_ kind: Toast.Kind, title: String, body: String? = nil,
              action: Action? = nil, duration: TimeInterval? = nil) {
        let toast = Toast(kind: kind, title: title, body: body, action: action)
        // 显式加动画：current 是在这里改的，不包 withAnimation 的话
        // ToastBanner 上的 transition 不会播，toast 是「啪」一下出现的。
        withAnimation(Self.appearAnimation) { current = toast }
        let dur = duration ?? (action == nil ? ToastCenter.defaultDuration : ToastCenter.actionDuration)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(dur * 1_000_000_000))
            // 只清理自己触发的那一条。写成 current?.id == current?.id 是恒真判断，
            // 会让先发 toast 的定时器把后来者提前清掉（如 streak 奖励提示被截断）。
            if current?.id == toast.id {
                withAnimation(Self.appearAnimation) { current = nil }
            }
        }
    }

    /// 从上方滑入并淡入，收回时反向播放
    static let appearAnimation = Animation.spring(response: 0.34, dampingFraction: 0.86)
}

struct ToastBanner: View {
    let toast: ToastCenter.Toast

    var body: some View {
        HStack(spacing: Spacing.s2) {
            Image(systemName: iconName)
                .frame(width: 28, height: 28)
                .background(foreground.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title).font(.kami(.body, size: 14))
                if let b = toast.body {
                    Text(b).font(.kami(.body, size: 12))
                        .foregroundStyle(foreground.opacity(0.9))
                }
            }
            Spacer()
            if let action = toast.action {
                Button(action.title) { action.handler() }
                    .font(.kami(.body, size: 14))
                    .foregroundStyle(foreground)
                    .padding(.horizontal, Spacing.s2)
                    .padding(.vertical, 4)
                    .background(foreground.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }
        }
        .padding(Spacing.s3)
        .foregroundStyle(foreground)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .padding(.horizontal, Spacing.s4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var iconName: String {
        switch toast.kind {
        case .success: return "checkmark"
        case .danger:  return "exclamationmark"
        case .info:    return "info"
        }
    }

    /// toast 自带一套底色和字色。深色模式下 success/danger/accent 都是浅色，
    /// 白字压在上面看不清，所以这里用专门的深底浅字配色。
    private var background: Color {
        switch toast.kind {
        case .success: return .kami.toastSuccessBg
        case .danger:  return .kami.toastDangerBg
        case .info:    return .kami.toastInfoBg
        }
    }

    private var foreground: Color {
        switch toast.kind {
        case .success: return .kami.toastSuccessFg
        case .danger:  return .kami.toastDangerFg
        case .info:    return .kami.toastInfoFg
        }
    }
}
