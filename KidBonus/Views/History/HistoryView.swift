import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \HistoryRecord.timestamp, order: .reverse) private var all: [HistoryRecord]
    // 按名字排序：不排序的话 @Query 的顺序不稳定，两个孩子会换位置
    @Query(sort: \Kid.name) private var kids: [Kid]
    @Environment(\.modelContext) private var ctx
    @Environment(ToastCenter.self) private var toast
    @State private var filter: String = "all"
    @State private var anchorDate: Date = Calendar.current.startOfDay(for: .now)
    @State private var dateRange: HistoryDateRange = .month
    @State private var showCalendar = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    Text("历程").font(.kami(.body, size: 28))
                        .padding(.horizontal, Spacing.s4)

                    HStack(spacing: Spacing.s2) {
                        chip("全部", id: "all")
                        ForEach(kids) { k in chip(k.name, id: k.id.uuidString) }
                    }
                    .padding(.horizontal, Spacing.s4)

                    dateFilter
                        .padding(.horizontal, Spacing.s4)

                    let selectedKidID = filter == "all" ? nil : UUID(uuidString: filter)
                    let filtered = HistoryGrouping.filter(all.entries, kidID: selectedKidID,
                                                         dateRange: dateRange, anchor: anchorDate)
                    if filtered.isEmpty {
                        Text(emptyText)
                            .font(.kami(.body, size: 12))
                            .foregroundStyle(Color.kami.meta)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.kami.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(Color.kami.border, lineWidth: 1)
                            )
                            .padding(.horizontal, Spacing.s4)
                    } else {
                        ForEach(HistoryGrouping.group(filtered)) { group in
                            VStack(alignment: .leading, spacing: Spacing.s2) {
                                Text(HistoryGrouping.label(for: group.key))
                                    .font(.kami(.body, size: 11))
                                    .foregroundStyle(Color.kami.meta)
                                    .padding(.horizontal, Spacing.s4)
                                ForEach(group.entries) { h in
                                    SwipeToDelete { delete(h) } content: {
                                        row(for: h)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
    }

    /// 折叠时是一行摘要，展开后是日历加三个区间按钮。
    private var dateFilter: some View {
        VStack(spacing: Spacing.s3) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showCalendar.toggle() }
            } label: {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.kami.accent)
                    Text("日期筛选").font(.kami(.body, size: 14))
                    Spacer()
                    Text(rangeSummary)
                        .font(.kami(.body, size: 12))
                        .foregroundStyle(Color.kami.meta)
                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.kami.meta)
                }
                .padding(Spacing.s3)
                .background(Color.kami.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.kami.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if showCalendar {
                VStack(spacing: Spacing.s3) {
                    DatePicker("日期", selection: $anchorDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        // 系统日历跟随系统语言，这里固定成中文，和页面上其它日期一致
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                        .onChange(of: anchorDate) { _, _ in
                            // 在日历上直接点某一天，就先切到「当天」
                            dateRange = .day
                        }

                    HStack(spacing: Spacing.s2) {
                        ForEach(HistoryDateRange.allCases) { r in
                            rangeChip(r)
                        }
                    }
                }
                .padding(Spacing.s3)
                .background(Color.kami.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.kami.border, lineWidth: 1)
                )
            }
        }
    }

    private var rangeSummary: String {
        let w = dateRange.window(anchor: anchorDate)
        if dateRange == .day {
            return HistoryGrouping.shortDate(w.end)
        }
        return "\(HistoryGrouping.shortDate(w.start)) - \(HistoryGrouping.shortDate(w.end))"
    }

    /// 全部时间都没有记录，和「这段时间没有记录」要分开说。
    private var emptyText: String {
        all.isEmpty ? "还没有记录，去加减分页记一笔吧。" : "这段时间没有记录，换个日期看看。"
    }

    /// 当天 / 近7天 / 近30天 三个区间按钮
    private func rangeChip(_ r: HistoryDateRange) -> some View {
        Button { dateRange = r } label: {
            Text(r.label)
                .font(.kami(.body, size: 14))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(dateRange == r ? Color.kami.surface : Color.kami.surfaceWarm)
                .foregroundStyle(dateRange == r ? Color.kami.accent : Color.kami.muted)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(dateRange == r ? Color.kami.accent : Color.kami.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func chip(_ text: String, id: String) -> some View {        Button { filter = id } label: {
            Text(text)
                .font(.kami(.body, size: 14))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(filter == id ? Color.kami.surface : Color.kami.surfaceWarm)
                .foregroundStyle(filter == id ? Color.kami.accent : Color.kami.muted)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(filter == id ? Color.kami.accent : Color.kami.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func row(for h: HistoryEntry) -> some View {
        let icon = iconStyle(for: h)
        return HStack(alignment: .top, spacing: Spacing.s3) {
            Image(systemName: icon.name)
                .font(.system(size: 16))
                .foregroundStyle(icon.fg)
                .frame(width: 34, height: 34)
                .background(icon.bg)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(h.title).font(.kami(.body, size: 13))
                Text("\(kidName(for: h.kidID)) · \(HistoryGrouping.timeText(h.timestamp))")
                    .font(.kami(.body, size: 11)).foregroundStyle(Color.kami.meta)
            }
            Spacer()
            Text("\(h.delta > 0 ? "+" : "")\(h.delta)")
                .font(.kami(.body, size: 14))
                .foregroundStyle(h.delta > 0 ? Color.kami.success : Color.kami.danger)
        }
        .padding(.horizontal, Spacing.s3)
        .padding(.vertical, Spacing.s2)
        .padding(.leading, Spacing.s4)
    }

    /// 行首图标按来源和正负区分，和加减分页的积分项图标同一套画法。
    private func iconStyle(for h: HistoryEntry) -> (name: String, fg: Color, bg: Color) {
        switch h.sourceKind {
        case .streakBonus: return ("flame.fill", .kami.warn, Color(hex: 0xEFE7D3))
        case .freeform:    return ("pencil", .kami.muted, .kami.tagBgFaint)
        case .redemption:  return ("gift", .kami.accent, .kami.tagBgSoft)
        case .adjust:      return ("slider.horizontal.3", .kami.accent, .kami.tagBgSoft)
        case .preset:
            return h.delta > 0
                ? ("checkmark", .kami.accent, .kami.tagBgSoft)
                : ("exclamationmark", .kami.danger, Color(hex: 0xEFE2DF))
        }
    }

    private func kidName(for id: UUID?) -> String {
        kids.first { $0.id == id }?.name ?? ""
    }

    /// 删除一条记录：积分是历史与兑换的汇总值，删掉即回调，这里只提示回调了多少。
    private func delete(_ h: HistoryEntry) {
        guard let record = all.first(where: { $0.id == h.id }) else {
            toast.show(.danger, title: "这条记录已经不在了")
            return
        }
        let who = kidName(for: h.kidID)
        let points = RecordStore.deleteRecord(record, ctx: ctx)
        toast.show(.success, title: "已删除「\(h.title)」",
                   body: "回调 \(abs(h.delta)) 分 · \(who)当前 \(points) 分")
    }
}

/// 右滑露出删除按钮。列表是 ScrollView + VStack 而不是 List，
/// 系统 swipeActions 在这里不生效，只能自己实现。
private struct SwipeToDelete<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var isOpen = false
    @State private var x: CGFloat = 0
    private let buttonWidth: CGFloat = 84

    var body: some View {
        ZStack(alignment: .leading) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.kami.bg)
                .offset(x: x)
                // simultaneousGesture：与外层 ScrollView 共存，竖向滑动仍能滚动
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { v in
                            let base = isOpen ? buttonWidth : 0
                            x = min(max(base + v.translation.width, 0), buttonWidth)
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                isOpen = x > buttonWidth / 2
                                x = isOpen ? buttonWidth : 0
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
                        .background(Color(hex: 0xEFE2DF))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
