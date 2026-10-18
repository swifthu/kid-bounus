import SwiftUI

@Observable
final class ToastCenter {
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let kind: Kind
        let title: String
        let body: String?
        enum Kind: Equatable { case info, success, danger }
    }
    var current: Toast?

    static let defaultDuration: TimeInterval = 2.4

    @MainActor
    func show(_ kind: Toast.Kind, title: String, body: String? = nil,
              duration: TimeInterval = ToastCenter.defaultDuration) {
        let toast = Toast(kind: kind, title: title, body: body)
        current = toast
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            // 只清理自己触发的那一条。写成 current?.id == current?.id 是恒真判断，
            // 会让先发 toast 的定时器把后来者提前清掉（如 streak 奖励提示被截断）。
            if current?.id == toast.id { current = nil }
        }
    }
}

struct ToastBanner: View {
    let toast: ToastCenter.Toast

    var body: some View {
        HStack(spacing: Spacing.s2) {
            Image(systemName: iconName)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title).font(.kami(.body, size: 14))
                if let b = toast.body {
                    Text(b).font(.kami(.body, size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            Spacer()
        }
        .padding(Spacing.s3)
        .foregroundStyle(.white)
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
    private var background: Color {
        switch toast.kind {
        case .success: return .kami.success
        case .danger:  return .kami.danger
        case .info:    return .kami.accent
        }
    }
}
