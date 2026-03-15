import Foundation

struct UpdateService {
    struct Release {
        let version: String
        let url: String
        let notes: String
        let publishedAt: String
    }

    static let currentVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }()

    static func checkForUpdate() async -> Release? {
        guard let url = URL(string: "https://api.github.com/repos/OpenStruct/dx-tools/releases/latest") else { return nil }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

            guard let tagName = json["tag_name"] as? String else { return nil }
            let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            let notes = json["body"] as? String ?? ""
            let publishedAt = json["published_at"] as? String ?? ""
            let htmlURL = json["html_url"] as? String ?? "https://github.com/OpenStruct/dx-tools/releases/latest"

            // Find DMG download URL
            var dmgURL = htmlURL
            if let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let name = asset["name"] as? String, name.hasSuffix(".dmg"),
                       let downloadURL = asset["browser_download_url"] as? String {
                        dmgURL = downloadURL
                        break
                    }
                }
            }

            guard isNewer(latestVersion, than: currentVersion) else { return nil }

            return Release(version: latestVersion, url: dmgURL, notes: notes, publishedAt: publishedAt)
        } catch {
            return nil
        }
    }

    static func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }
}
