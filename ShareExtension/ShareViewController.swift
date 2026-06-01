import UIKit
import UniformTypeIdentifiers

@MainActor
class ShareViewController: UIViewController {
    private let appGroupID = "group.cc.sengokyu.Tundokuko"
    private let pendingURLKey = "pendingNovelURL"

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

        if let url {
            UserDefaults(suiteName: appGroupID)?.set(url.absoluteString, forKey: pendingURLKey)
        }

        openMainApp()
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
