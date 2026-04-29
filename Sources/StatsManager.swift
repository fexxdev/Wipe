import Foundation

struct CleaningSession: Codable {
    let date: Date
    let duration: TimeInterval
    let color: String
}

class StatsManager: ObservableObject {
    static let shared = StatsManager()

    @Published var totalSessions: Int
    @Published var totalCleaningTime: TimeInterval
    @Published var longestSession: TimeInterval
    @Published var colorCounts: [String: Int]
    @Published var firstLaunchDate: Date
    @Published var analyticsEnabled: Bool

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
            sendLaunchPing()
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

    private func save() {
        defaults.set(totalSessions, forKey: "stats.totalSessions")
        defaults.set(totalCleaningTime, forKey: "stats.totalCleaningTime")
        defaults.set(longestSession, forKey: "stats.longestSession")
        if let data = try? JSONEncoder().encode(colorCounts) {
            defaults.set(data, forKey: "stats.colorCounts")
        }
    }

    private func sendLaunchPing() {
        // Anonymous launch ping — no device ID, no user data, just a counter hit.
        // Set your own endpoint (e.g. Cloudflare Worker, Vercel function).
        // Example Worker: addEventListener("fetch", e => { count++; return new Response("ok") })
        guard let url = URL(string: "https://YOUR_ENDPOINT/wipe/launch") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Wipe/1.0.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 5
        URLSession.shared.dataTask(with: request).resume()
    }
}
