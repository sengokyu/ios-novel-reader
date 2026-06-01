import UIKit
import UniformTypeIdentifiers

@MainActor
class ShareViewController: UIViewController {
    private let appGroupID = "group.cc.sengokyu.Tundokuko"
    private let pendingURLKey = "pendingNovelURL"

    // Mirrors NarouAdapter.hosts — update when new site adapters are added
    private static let supportedHosts: Set<String> = ["ncode.syosetu.com", "novel18.syosetu.com"]

    private var okContinuation: CheckedContinuation<Void, Never>?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupCardBackground()
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
            await showCard(
                message: "このURLは対応していません。\n対応サイト: 小説家になろう",
                buttonTitle: "OK"
            )
            return
        }

        UserDefaults(suiteName: appGroupID)?.set(url.absoluteString, forKey: pendingURLKey)
        await showSuccessAndDismiss()
    }

    private static func isSupported(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return supportedHosts.contains(host)
    }

    // MARK: - Card UI

    private func setupCardBackground() {
        view.backgroundColor = .systemBackground
    }

    private func makeHeaderView() -> UIView {
        let iconSize: CGFloat = 32
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false

        if let appIcon = UIImage(named: "AppIcon") {
            iconView.image = appIcon
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: iconSize * 0.6, weight: .regular)
            iconView.image = UIImage(systemName: "books.vertical.fill", withConfiguration: config)
            iconView.tintColor = .systemBrown
        }

        let nameLabel = UILabel()
        nameLabel.text = "Tundokuko"
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .label

        let stack = UIStackView(arrangedSubviews: [iconView, nameLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),
        ])

        return stack
    }

    private func showSuccessAndDismiss() async {
        let messageLabel = UILabel()
        messageLabel.text = "登録しました"
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textColor = .label
        messageLabel.textAlignment = .center

        let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        icon.tintColor = .systemGreen
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        icon.preferredSymbolConfiguration = config

        let contentStack = UIStackView(arrangedSubviews: [icon, messageLabel])
        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.alignment = .center

        installCard(content: contentStack, button: nil)

        try? await Task.sleep(for: .seconds(1))
        finish()
    }

    private func showCard(message: String, buttonTitle: String) async {
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textColor = .label
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle(buttonTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)

        installCard(content: messageLabel, button: button)

        await withCheckedContinuation { continuation in
            okContinuation = continuation
        }
    }

    @objc private func okButtonTapped() {
        finish()
        okContinuation?.resume()
        okContinuation = nil
    }

    private func installCard(content: UIView, button: UIView?) {
        view.subviews.forEach { $0.removeFromSuperview() }

        let header = makeHeaderView()

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false

        var arranged: [UIView] = [header, separator, content]
        if let button { arranged.append(button) }

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
