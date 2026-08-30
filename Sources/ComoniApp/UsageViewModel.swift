import Foundation
import Combine

#if SWIFT_PACKAGE
import ComoniCore
#endif

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var snapshot: UsageDisplaySnapshot?
    @Published private(set) var isRefreshing = false
    @Published private(set) var updatedAt: Date?
    @Published private(set) var errorMessage: String?

    var isStale: Bool {
        snapshot != nil && errorMessage != nil
    }

    func refresh() {
        guard !isRefreshing else {
            return
        }
        isRefreshing = true

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let result = Result {
                try UsageDisplaySnapshot(
                    response: CodexAppServerClient.resolved().readRateLimits()
                )
            }
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                self.isRefreshing = false
                switch result {
                case let .success(snapshot):
                    self.snapshot = snapshot
                    self.updatedAt = Date()
                    self.errorMessage = nil
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
