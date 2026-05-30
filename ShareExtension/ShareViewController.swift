//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by ziyi on R 8/05/30.
//

import Social
import UIKit
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    private let appGroupID = "group.cc.sengokyu.Tundokuko"
    private let pendingURLKey = "pendingNovelURL"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "積読庫に追加"
        placeholder = "小説URLを本棚に登録します"
    }

    override func isContentValid() -> Bool {
        true
    }

    override func didSelectPost() {
        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let provider = item.attachments?.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.url.identifier)
            })
        else {
            close()
            return
        }

        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
            defer { self?.close() }
            guard let url = item as? URL, let self else { return }
            UserDefaults(suiteName: self.appGroupID)?.set(url.absoluteString, forKey: self.pendingURLKey)
        }
    }

    override func configurationItems() -> [Any]! {
        []
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
