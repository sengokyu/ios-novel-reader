import UIKit
import UniformTypeIdentifiers

@MainActor
class ShareViewController: UIViewController {
    private let appGroupID = "group.cc.sengokyu.Tundokuko"
    private let pendingURLKey = "pendingNovelURL"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        setupUI()
        Task { await extractAndSave() }
    }

    // MARK: - Private

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "books.vertical.fill"))
        icon.tintColor = .systemBrown
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 48).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let title = UILabel()
        title.text = "積読庫に追加"
        title.font = .preferredFont(forTextStyle: .headline)

        let subtitle = UILabel()
        subtitle.text = "URLを登録しています..."
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = .secondaryLabel

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

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
