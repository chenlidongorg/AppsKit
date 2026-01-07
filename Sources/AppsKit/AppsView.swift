import SwiftUI
import Combine
import UIKit

@available(iOS 14.0, *)
public struct AppsView: View {
    private let requesrBaseURL: String
    private let requestJsonName: String
    private let triggerView: AnyView?
    private let onActive: (Bool) -> Void

    @StateObject private var viewModel: AppsViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var isPresentingList = false

    public init(
        requesrBaseURL: String = "https://xxx.com",
        requestJsonName: String = "xxx.json",
        triggerView: AnyView? = nil,
        onActive: @escaping (Bool) -> Void = { _ in }
    ) {
        self.requesrBaseURL = requesrBaseURL
        self.requestJsonName = requestJsonName
        self.triggerView = triggerView
        self.onActive = onActive
        _viewModel = StateObject(wrappedValue: AppsViewModel(baseURL: requesrBaseURL, jsonName: requestJsonName))
    }

    public init<Trigger: View>(
        requesrBaseURL: String = "https://xxx.com",
        requestJsonName: String = "xxx.json",
        @ViewBuilder triggerView: () -> Trigger,
        onActive: @escaping (Bool) -> Void = { _ in }
    ) {
        self.requesrBaseURL = requesrBaseURL
        self.requestJsonName = requestJsonName
        self.triggerView = AnyView(triggerView())
        self.onActive = onActive
        _viewModel = StateObject(wrappedValue: AppsViewModel(baseURL: requesrBaseURL, jsonName: requestJsonName))
    }

    public var body: some View {
        Group {
            if let triggerView = triggerView {
                triggerButton(triggerView)
            } else {
                appsNavigationView
            }
        }
        .onAppear {
            print("load(baseURL onAppear ")
            viewModel.loadIfNeeded(baseURL: requesrBaseURL, jsonName: requestJsonName)
        }
        .onReceive(viewModel.$appsModel.compactMap { $0?.active }.removeDuplicates()) { value in
            onActive(value)
        }
        
        
        
        .sheet(isPresented: $isPresentingList) {
            appsNavigationView
        }
        
    }

    private var appsNavigationView: some View {
        NavigationView {
            appsContent
                .navigationBarTitle(LocalizedInfo.Name, displayMode: .inline)
                .navigationBarItems(leading: closeButton)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private var appsContent: some View {
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

    @ViewBuilder
    private func triggerButton(_ triggerView: AnyView) -> some View {
        
        if viewModel.appsModel?.active == true {
            Button(action: { isPresentingList = true }) {
                triggerView
            }
            .buttonStyle(PlainButtonStyle())
            //.opacity(viewModel.appsModel?.active == true ? 1.0 : 0.01)
        }
        
       /*
        if viewModel.appsModel?.active == true {
            
            Button(action: { isPresentingList = true }) {
                triggerView
            }
            .buttonStyle(PlainButtonStyle())
            
        } else {
            
            Color.secondary.opacity(0.3)
                .frame(width: 2, height: 2)
        }
        */
    }

    private var closeButton: some View {
        Button(action: close) {
            Image(systemName: "xmark")
                .foregroundColor(Color(red: 0.1, green: 0.12, blue: 0.16))
        }
    }

    private func close() {
        if isPresentingList {
            isPresentingList = false
        } else {
            presentationMode.wrappedValue.dismiss()
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
    private let decodeQueue = DispatchQueue(label: "AppsKit.AppsViewModel.decode", qos: .userInitiated)

    init(baseURL: String, jsonName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.load(baseURL: baseURL, jsonName: jsonName)
        }
    }

    func loadIfNeeded(baseURL: String, jsonName: String) {
        guard appsModel == nil else { return }
        load(baseURL: baseURL, jsonName: jsonName)
    }

    func load(baseURL: String, jsonName: String) {
        
        print("load(baseURL 1",baseURL ,jsonName)
        guard state != .loading else { return }
        guard let url = URLBuilder.jsonURL(baseURL: baseURL, jsonName: jsonName) else {
            state = .failed("Invalid JSON URL")
            appsModel = nil
            return
        }

        print("load(baseURL 2", url)
        
        state = .loading
        cancellable?.cancel()

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .subscribe(on: decodeQueue)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse,
                      (200...299).contains(response.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
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
                
                print("model:", model)
            })
    }
}

@available(iOS 14.0, *)
struct AppsListView: View {
    let apps: [AppModel]
    let baseURL: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible(), spacing: 16)]
        }
        return [GridItem(.adaptive(minimum: 280), spacing: 16)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(apps) { app in
                    AppCardView(app: app, baseURL: baseURL)
                        .frame(maxWidth: horizontalSizeClass == .compact ? .infinity : 420)
                        .frame(maxWidth: .infinity, alignment: .center)
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
    if #available(iOS 14.0, *) {
        AppsKit.AppsView(requesrBaseURL: "https://files.whiteboardapp.cn", requestJsonName: "whiteboard_apps.json", triggerView: AnyView(
            
            HStack{
                
                Image(uiImage: AppsKit.LocalizedInfo.Logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth:22)
                
                Text(AppsKit.LocalizedInfo.Name)
                
            }
        )){ active in
            
            print("active",active)
            
        }
    }
}
