import SwiftUI
import Combine
import UIKit

public struct AppsView: View {
    private let requesrBaseURL: String
    private let requestJsonName: String
    private let onActive: (Bool) -> Void

    @ObservedObject private var viewModel: AppsViewModel

    public init(
        requesrBaseURL: String = "https://xxx.com",
        requestJsonName: String = "xxx.json",
        onActive: @escaping (Bool) -> Void = { _ in }
    ) {
        self.requesrBaseURL = requesrBaseURL
        self.requestJsonName = requestJsonName
        self.onActive = onActive
        _viewModel = ObservedObject(wrappedValue: AppsViewModel())
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                LoadingView()
            case .failed(let message):
                ErrorView(message: message) {
                    viewModel.load(baseURL: requesrBaseURL, jsonName: requestJsonName)
                }
            case .idle:
                if let model = viewModel.appsModel, model.active {
                    AppsListView(apps: model.apps, baseURL: requesrBaseURL)
                } else if viewModel.appsModel != nil {
                    EmptyView()
                } else {
                    LoadingView()
                }
            }
        }
        .onAppear {
            viewModel.load(baseURL: requesrBaseURL, jsonName: requestJsonName)
        }
        .onReceive(viewModel.$appsModel.compactMap { $0?.active }.removeDuplicates()) { value in
            onActive(value)
        }
    }
}

final class AppsViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case failed(String)
    }

    @Published private(set) var appsModel: AppsModel?
    @Published private(set) var state: State = .idle

    private var cancellable: AnyCancellable?

    func load(baseURL: String, jsonName: String) {
        guard state != .loading else { return }
        guard let url = URLBuilder.jsonURL(baseURL: baseURL, jsonName: jsonName) else {
            state = .failed("Invalid JSON URL")
            return
        }

        state = .loading
        cancellable?.cancel()

        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AppsModel.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.state = .failed(error.localizedDescription)
                case .finished:
                    self?.state = .idle
                }
            }, receiveValue: { [weak self] model in
                self?.appsModel = model
            })
    }
}

struct AppsListView: View {
    let apps: [AppModel]
    let baseURL: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(apps) { app in
                    AppCardView(app: app, baseURL: baseURL)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.93),
                    Color(red: 0.93, green: 0.95, blue: 0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
        )
    }
}

struct AppCardView: View {
    let app: AppModel
    let baseURL: String

    private var nameText: String {
        LanguageResolver.localizedString(from: app.name)
    }

    private var summaryText: String {
        LanguageResolver.localizedString(from: app.summary)
    }

    private var iconURL: URL? {
        URLBuilder.iconURL(baseURL: baseURL, iconName: app.iconName)
    }

    private var downloadURL: URL? {
        URL(string: app.downloadURL)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RemoteImage(url: iconURL, size: 54)
                VStack(alignment: .leading, spacing: 6) {
                    Text(nameText)
                        .font(.headline)
                        .foregroundColor(Color(red: 0.1, green: 0.12, blue: 0.16))
                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.36, green: 0.4, blue: 0.46))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }

            HStack {
                Spacer()
                Button(action: openDownload) {
                    Text("Install")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(Color(red: 0.12, green: 0.52, blue: 0.96))
                        )
                }
                .disabled(downloadURL == nil)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }

    private func openDownload() {
        guard let url = downloadURL else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ActivityIndicator(isAnimating: true, style: .large)
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(Color(red: 0.4, green: 0.42, blue: 0.46))
        }
        .padding(24)
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Failed to load")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(Color(red: 0.5, green: 0.52, blue: 0.56))
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Text("Retry")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color(red: 0.8, green: 0.33, blue: 0.31))
                    )
            }
        }
        .padding(24)
    }
}

struct ActivityIndicator: UIViewRepresentable {
    let isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: style)
        view.hidesWhenStopped = true
        return view
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        if isAnimating {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}

enum URLBuilder {
    static func jsonURL(baseURL: String, jsonName: String) -> URL? {
        if let direct = URL(string: jsonName), direct.scheme != nil {
            return direct
        }
        guard let base = URL(string: baseURL) else { return nil }
        return URL(string: jsonName, relativeTo: base)?.absoluteURL
    }

    static func iconURL(baseURL: String, iconName: String) -> URL? {
        if let direct = URL(string: iconName), direct.scheme != nil {
            return direct
        }
        guard let base = URL(string: baseURL) else { return nil }
        return URL(string: iconName, relativeTo: base)?.absoluteURL
    }
}


#Preview {
    AppsView(requesrBaseURL: "https://files.endlessai.org",requestJsonName: "whiteboard_apps.json"){ active in
        
        print("active",active)
    }
}
