import SwiftUI
import Combine
import UIKit

final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false

    private var cancellable: AnyCancellable?
    private var currentURL: URL?

    func load(from url: URL?) {
        guard let url = url else {
            cancellable?.cancel()
            cancellable = nil
            currentURL = nil
            image = nil
            isLoading = false
            return
        }

        if url != currentURL {
            image = nil
        }

        currentURL = url
        cancellable?.cancel()
        isLoading = true

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.image = image
                self?.isLoading = false
            }
    }

    func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }
}

struct RemoteImage: View {
    let url: URL?
    let size: CGFloat

    @ObservedObject private var loader: ImageLoader

    init(url: URL?, size: CGFloat) {
        self.url = url
        self.size = size
        _loader = ObservedObject(wrappedValue: ImageLoader())
    }

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.9, green: 0.92, blue: 0.95))
                Image(systemName: "app.fill")
                    .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .onAppear {
            loader.load(from: url)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
