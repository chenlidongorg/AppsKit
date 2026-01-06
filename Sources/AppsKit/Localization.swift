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
    static func preferredLanguageCodes() -> [String] {
        var results: [String] = []
        var seen = Set<String>()

        for language in Locale.preferredLanguages {
            let normalized = language.replacingOccurrences(of: "_", with: "-").lowercased()
            let candidates = [normalized, normalized.split(separator: "-").first.map(String.init)].compactMap { $0 }

            for code in candidates {
                if !seen.contains(code) {
                    results.append(code)
                    seen.insert(code)
                }
            }
        }

        return results
    }

    static func localizedString(from map: [String: String]) -> String {
        guard !map.isEmpty else { return "" }

        let normalizedMap = Dictionary(uniqueKeysWithValues: map.map { ($0.key.lowercased(), $0.value) })

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
