import SwiftUI

@Observable
final class ToastCenter {
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let kind: Kind
        let title: String
        let body: String?
        enum Kind { case info, success, danger }
    }
    var current: Toast?

    @MainActor
    func show(_ kind: Toast.Kind, title: String, body: String? = nil) {
        current = Toast(kind: kind, title: title, body: body)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            if current?.id == current?.id { current = nil }
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
