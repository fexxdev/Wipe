import SwiftUI

struct StatsView: View {
    @ObservedObject var stats = StatsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Stats")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                statRow("Sessions", value: "\(stats.totalSessions)")
                statRow("Total time", value: formatDuration(stats.totalCleaningTime))
                statRow("Average session", value: formatDuration(stats.averageSession))
                statRow("Longest session", value: formatDuration(stats.longestSession))
                statRow("Favorite color", value: stats.favoriteColor)
                statRow("Using since", value: formatDate(stats.firstLaunchDate))
            }

            Divider()

            Toggle("Anonymous analytics", isOn: Binding(
                get: { stats.analyticsEnabled },
                set: { stats.setAnalytics(enabled: $0) }
            ))
            .font(.callout)

            Text("Only counts app launches — no personal data collected")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 320)
    }

    private func statRow(_ label: String, value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        if t < 60 { return "\(Int(t))s" }
        let m = Int(t) / 60
        let s = Int(t) % 60
        if m < 60 { return "\(m)m \(s)s" }
        let h = m / 60
        return "\(h)h \(m % 60)m"
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
