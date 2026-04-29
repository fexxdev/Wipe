import Foundation

@MainActor
class StatsManager: ObservableObject {
    static let shared = StatsManager()

    nonisolated static let analyticsBaseURL = "https://wipe-analytics.fexxdev.workers.dev"

    @Published var totalSessions: Int
    @Published var totalCleaningTime: TimeInterval
    @Published var longestSession: TimeInterval
    @Published var colorCounts: [String: Int]
    @Published var firstLaunchDate: Date
    @Published var analyticsEnabled: Bool

    @Published var globalLaunches: Int = 0
    @Published var globalSessions: Int = 0
    @Published var globalCleaningTime: TimeInterval = 0
    @Published var todayActive: Int = 0

    private let defaults = UserDefaults.standard

    private init() {
        totalSessions = defaults.integer(forKey: "stats.totalSessions")
        totalCleaningTime = defaults.double(forKey: "stats.totalCleaningTime")
        longestSession = defaults.double(forKey: "stats.longestSession")
        firstLaunchDate = defaults.object(forKey: "stats.firstLaunch") as? Date ?? Date()
        analyticsEnabled = defaults.object(forKey: "stats.analyticsEnabled") as? Bool ?? true

        if let data = defaults.data(forKey: "stats.colorCounts"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            colorCounts = decoded
        } else {
            colorCounts = [:]
        }

        if defaults.object(forKey: "stats.firstLaunch") == nil {
            defaults.set(Date(), forKey: "stats.firstLaunch")
        }

        if analyticsEnabled {
            postFireAndForget("/launch")
        }
    }

    func recordSession(duration: TimeInterval, dominantColor: CleaningColor) {
        totalSessions += 1
        totalCleaningTime += duration
        if duration > longestSession {
            longestSession = duration
        }

        let key = dominantColor.label
        colorCounts[key, default: 0] += 1

        save()

        if analyticsEnabled {
            postFireAndForget("/session", body: ["duration": duration])
        }
    }

    var favoriteColor: String {
        colorCounts.max(by: { $0.value < $1.value })?.key ?? "—"
    }

    var averageSession: TimeInterval {
        totalSessions > 0 ? totalCleaningTime / Double(totalSessions) : 0
    }

    func setAnalytics(enabled: Bool) {
        analyticsEnabled = enabled
        defaults.set(enabled, forKey: "stats.analyticsEnabled")
    }

    func fetchGlobalStats() {
        guard analyticsEnabled else { return }
        guard let url = URL(string: "\(Self.analyticsBaseURL)/stats") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        Task {
            guard let (data, _) = try? await URLSession.shared.data(for: request),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return }
            globalLaunches = json["launches"] as? Int ?? 0
            globalSessions = json["totalSessions"] as? Int ?? 0
            globalCleaningTime = json["totalCleaningTimeSeconds"] as? Double ?? 0
            todayActive = json["todayActive"] as? Int ?? 0
        }
    }

    private func save() {
        defaults.set(totalSessions, forKey: "stats.totalSessions")
        defaults.set(totalCleaningTime, forKey: "stats.totalCleaningTime")
        defaults.set(longestSession, forKey: "stats.longestSession")
        if let data = try? JSONEncoder().encode(colorCounts) {
            defaults.set(data, forKey: "stats.colorCounts")
        }
    }

    private nonisolated func postFireAndForget(_ path: String, body: [String: Any]? = nil) {
        guard let url = URL(string: "\(Self.analyticsBaseURL)\(path)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 5
        request.setValue("Wipe/1.0.0", forHTTPHeaderField: "User-Agent")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        URLSession.shared.dataTask(with: request).resume()
    }
}
