import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \HistoryRecord.timestamp, order: .reverse) private var all: [HistoryRecord]
    @Query private var kids: [Kid]
    @State private var filter: String = "all"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("历程").font(.kami(.body, size: 28))
                        Text("按天分组，最近 30 天。")
                            .font(.kami(.body, size: 14))
                            .foregroundStyle(Color.kami.muted)
                    }
                    .padding(.horizontal, Spacing.s4)

                    HStack(spacing: Spacing.s2) {
                        chip("全部", id: "all")
                        ForEach(kids) { k in chip(k.name, id: k.id.uuidString) }
                    }
                    .padding(.horizontal, Spacing.s4)

                    let selectedKidID = filter == "all" ? nil : UUID(uuidString: filter)
                    let filtered = HistoryGrouping.filter(all.entries, kidID: selectedKidID)
                    if filtered.isEmpty {
                        Text("还没有记录，去加减分页记一笔吧。")
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
                                ForEach(group.entries) { h in row(for: h) }
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.s4)
            }
            .background(Color.kami.bg)
        }
    }

    private func chip(_ text: String, id: String) -> some View {
        Button { filter = id } label: {
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
        HStack(alignment: .top, spacing: Spacing.s3) {
            Circle()
                .fill(Color.kami.bg)
                .overlay(Circle().stroke(h.delta > 0 ? Color.kami.accent : Color.kami.danger, lineWidth: 1))
                .frame(width: 9, height: 9)
                .padding(.top, 8)
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

    private func kidName(for id: UUID?) -> String {
        kids.first { $0.id == id }?.name ?? ""
    }
}
