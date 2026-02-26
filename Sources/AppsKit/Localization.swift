import Foundation
import UIKit

extension String {
    var toLocalized: String {
        NSLocalizedString(self, bundle: Bundle.module, comment: "AppsKit localized string")
    }
}

public struct LocalizedInfo {
    public static var Logo: UIImage {
        UIImage(named: "logo", in: Bundle.module, with: nil) ?? UIImage()
    }

    public static var Name: String {
        "title".toLocalized
    }

    public static var Description: String {
        "description".toLocalized
    }
}

enum LanguageResolver {
    private static func normalizedLanguageCode(_ code: String) -> String {
        code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
    }

    private static func appendUnique(_ value: String, to results: inout [String], seen: inout Set<String>) {
        guard !value.isEmpty, !seen.contains(value) else { return }
        results.append(value)
        seen.insert(value)
    }

    private static func candidateCodes(for rawCode: String) -> [String] {
        let normalized = normalizedLanguageCode(rawCode)
        guard !normalized.isEmpty else { return [] }

        var results: [String] = []
        var seen = Set<String>()

        appendUnique(normalized, to: &results, seen: &seen)

        let parts = normalized.split(separator: "-").map(String.init)
        if parts.count > 1 {
            for end in stride(from: parts.count - 1, through: 1, by: -1) {
                appendUnique(parts[0..<end].joined(separator: "-"), to: &results, seen: &seen)
            }
        }

        if let language = parts.first, language == "zh" {
            let tokens = Set(parts.dropFirst())
            let simplifiedRegions: Set<String> = ["cn", "sg"]
            let traditionalRegions: Set<String> = ["tw", "hk", "mo"]

            if tokens.contains("hans") || !tokens.intersection(simplifiedRegions).isEmpty {
                appendUnique("zh-hans", to: &results, seen: &seen)
                appendUnique("zh-cn", to: &results, seen: &seen)
            }

            if tokens.contains("hant") || !tokens.intersection(traditionalRegions).isEmpty {
                appendUnique("zh-hant", to: &results, seen: &seen)
                appendUnique("zh-tw", to: &results, seen: &seen)
                appendUnique("zh-hk", to: &results, seen: &seen)
            }

            appendUnique("zh", to: &results, seen: &seen)
        }

        return results
    }

    static func preferredLanguageCodes() -> [String] {
        var results: [String] = []
        var seen = Set<String>()

        let languageSources: [String] =
            Bundle.main.preferredLocalizations +
            Bundle.module.preferredLocalizations +
            (UserDefaults.standard.array(forKey: "AppleLanguages") as? [String] ?? []) +
            Locale.preferredLanguages +
            [Locale.autoupdatingCurrent.identifier, Locale.current.identifier]

        for language in languageSources {
            for code in candidateCodes(for: language) {
                appendUnique(code, to: &results, seen: &seen)
            }
        }

        return results
    }

    static func localizedString(from map: [String: String]) -> String {
        guard !map.isEmpty else { return "" }

        var normalizedMap: [String: String] = [:]
        for (key, value) in map {
            let normalizedKey = normalizedLanguageCode(key)
            guard !normalizedKey.isEmpty else { continue }
            if normalizedMap[normalizedKey] == nil {
                normalizedMap[normalizedKey] = value
            }
        }

        for code in preferredLanguageCodes() {
            if let value = normalizedMap[code] {
                return value
            }
        }

        if let english = normalizedMap["en"] {
            return english
        }

        return normalizedMap.values.first ?? ""
    }
}
