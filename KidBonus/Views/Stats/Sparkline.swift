import SwiftUI
import Charts

struct Sparkline: View {
    let buckets: [TrendBucket]

    var body: some View {
        Chart(buckets, id: \.dateKey) { b in
            LineMark(x: .value("Day", b.dateKey),
                     y: .value("Net", b.value))
            .interpolationMethod(.catmullRom)
            AreaMark(x: .value("Day", b.dateKey),
                     y: .value("Net", b.value))
            .foregroundStyle(Color.kami.accent.opacity(0.1))
        }
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .chartYScale(domain: yDomain)
        .frame(height: 80)
    }

    private var yDomain: ClosedRange<Int> {
        let values = buckets.map { $0.value }
        let mn = min(0, values.min() ?? 0)
        let mx = max(1, values.max() ?? 0)
        let pad = max(1, Int(Double(mx - mn) * 0.1))
        return (mn - pad) ... (mx + pad)
    }
}
