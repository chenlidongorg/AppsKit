AppsKit

A Swift Package that fetches a remote apps list JSON and renders a polished SwiftUI list with localization support.

Requirements
- iOS 13+
- Swift Package Manager

Install
- Add the package to your project as a dependency.
- Ensure your app has network access to the JSON and icon host.

Usage

import SwiftUI
import AppsKit

struct ContentView: View {
    var body: some View {
        AppsView(
            requesrBaseURL: "https://example.com",
            requestJsonName: "apps.json"
        ) { active in
            // Use active to decide whether to show the list.
        }
    }
}

Data Format
The JSON must match the AppsModel structure. Use the template file `apps-template.json` as a starting point.

Rules
- All text fields are keyed by language code (e.g. "en", "zh-Hans").
- The view chooses the current app language, falls back to English, then the first available value.
- iconName is appended to requesrBaseURL to build the icon URL.

Localization Helpers
AppsKit provides a simple localizable helper:

LocalizedInfo.Name
LocalizedInfo.Description
LocalizedInfo.Logo

These values use string keys:
- "title"
- "description"

Update `Sources/AppsKit/Resources/*.lproj/Localizable.strings` with your own project name/description strings when integrating.

Public API
- AppsView(requesrBaseURL:requestJsonName:onActive:)
- LocalizedInfo
- AppModel / AppsModel
