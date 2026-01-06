import Foundation

public struct AppModel: Codable, Hashable, Identifiable {
    public let iconName: String
    public let downloadURL: String
    public let name: [String: String]
    public let summary: [String: String]

    public var id: String { downloadURL }

    public init(iconName: String, downloadURL: String, name: [String: String], summary: [String: String]) {
        self.iconName = iconName
        self.downloadURL = downloadURL
        self.name = name
        self.summary = summary
    }
}

public struct AppsModel: Codable, Hashable {
    public let active: Bool
    public let apps: [AppModel]

    public init(active: Bool = false, apps: [AppModel]) {
        self.active = active
        self.apps = apps
    }

    private enum CodingKeys: String, CodingKey {
        case active = "Active"
        case apps
    }

    private enum FallbackCodingKeys: String, CodingKey {
        case active = "active"
        case apps
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let appsValue = (try? container.decode([AppModel].self, forKey: .apps)) ?? []
        let activeValue = try? container.decode(Bool.self, forKey: .active)

        if let activeValue = activeValue {
            self.active = activeValue
        } else {
            let fallback = try decoder.container(keyedBy: FallbackCodingKeys.self)
            self.active = (try? fallback.decode(Bool.self, forKey: .active)) ?? false
        }

        self.apps = appsValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(active, forKey: .active)
        try container.encode(apps, forKey: .apps)
    }
}
