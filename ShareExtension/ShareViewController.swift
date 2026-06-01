import UIKit
import UniformTypeIdentifiers

@MainActor
class ShareViewController: UIViewController {
    private let appGroupID = "group.cc.sengokyu.Tundokuko"
    private let pendingURLKey = "pendingNovelURL"

    // Mirrors NarouAdapter.hosts — update when new site adapters are added
    private static let supportedHosts: Set<String> = ["ncode.syosetu.com", "novel18.syosetu.com"]

    override func viewDidLoad() {
        super.viewDidLoad()
        Task { await extractAndSave() }
    }

    // MARK: - Private

    private func extractAndSave() async {
        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let provider = item.attachments?.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.url.identifier)
            })
        else {
            finish()
            return
        }

        let url: URL? = await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                if let nsURL = item as? NSURL {
                    continuation.resume(returning: nsURL as URL)
                } else if let string = item as? String, let url = URL(string: string) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }

        guard let url else {
            finish()
            return
        }

        guard Self.isSupported(url: url) else {
            await showUnsupportedAlert()
            return
        }

        UserDefaults(suiteName: appGroupID)?.set(url.absoluteString, forKey: pendingURLKey)
        openMainApp()
    }

    private static func isSupported(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return supportedHosts.contains(host)
    }

    private func showUnsupportedAlert() async {
        await withCheckedContinuation { continuation in
            let alert = UIAlertController(
                title: "未対応のURL",
                message: "このURLは対応していません。\n対応サイト: 小説家になろう",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.finish()
                continuation.resume()
            })
            present(alert, animated: true)
        }
    }

    private func openMainApp() {
        guard let appURL = URL(string: "tundokuko://") else {
            finish()
            return
        }
        extensionContext?.open(appURL, completionHandler: { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.finish()
            }
        })
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
