import WebKit

// Bridges WebKit's ObjC delegates to Swift closures. All callbacks arrive on the main thread.
private final class WebViewDelegate: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var onNavigationFinished: (() -> Void)?
    var onScrollChanged: ((Double) -> Void)?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onNavigationFinished?()
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "scrollChanged", let offset = message.body as? Double else { return }
        onScrollChanged?(offset)
    }
}

@MainActor
final class ReaderController {
    var onScrollChanged: ((Double) -> Void)?

    private(set) var isNavigationReady = false
    private var pendingContent: (html: String, offset: Double?)?
    private var pendingSettings: (fontSize: Int, lineHeight: Double, height: Int, width: Int, fontFamily: String)?

    let webView: WKWebView
    private let delegate: WebViewDelegate

    init() {
        let del = WebViewDelegate()
        let userContent = WKUserContentController()
        userContent.add(del, name: "scrollChanged")
        let config = WKWebViewConfiguration()
        config.userContentController = userContent
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.scrollView.isScrollEnabled = false
        wv.scrollView.bounces = false
        wv.navigationDelegate = del
        #if DEBUG
        if #available(iOS 16.4, *) { wv.isInspectable = true }
        #endif
        webView = wv
        delegate = del

        // Wire delegate callbacks — all stored properties are initialized, self is safe
        del.onNavigationFinished = { [weak self] in
            Task { @MainActor [weak self] in self?.navigationDidFinish() }
        }
        del.onScrollChanged = { [weak self] offset in
            Task { @MainActor [weak self] in self?.onScrollChanged?(offset) }
        }

        // Pre-warm: load reader.html immediately so it's ready before the user opens the reader
        if let url = Bundle.main.url(forResource: "reader", withExtension: "html") {
            wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "scrollChanged")
    }

    private func navigationDidFinish() {
        isNavigationReady = true
        if let s = pendingSettings {
            pendingSettings = nil
            applySettings(fontSize: s.fontSize, lineHeight: s.lineHeight, height: s.height, width: s.width, fontFamily: s.fontFamily)
        }
        if let c = pendingContent {
            pendingContent = nil
            setContent(c.html, offset: c.offset)
        }
    }

    func setContent(_ html: String, offset: Double?) {
        guard let json = try? JSONEncoder().encode(html),
              let jsonString = String(data: json, encoding: .utf8) else { return }
        guard isNavigationReady else {
            pendingContent = (html, offset)
            return
        }
        let offsetArg = offset.map { "\($0)" } ?? "null"
        Task { @MainActor in
            _ = try? await webView.evaluateJavaScript("setContent(\(jsonString), \(offsetArg))")
        }
    }

    func pageForward() {
        Task { @MainActor [weak self] in
            _ = try? await self?.webView.evaluateJavaScript("pageForward()")
        }
    }

    func pageBack() {
        Task { @MainActor [weak self] in
            _ = try? await self?.webView.evaluateJavaScript("pageBack()")
        }
    }

    func applySettings(fontSize: Int, lineHeight: Double, height: Int, width: Int, fontFamily: String) {
        guard let ffJson = try? JSONEncoder().encode(fontFamily),
              let ffString = String(data: ffJson, encoding: .utf8) else { return }
        guard isNavigationReady else {
            pendingSettings = (fontSize, lineHeight, height, width, fontFamily)
            return
        }
        let js = "setStyles(\(fontSize), \(lineHeight), \(height), \(width), \(ffString))"
        Task { @MainActor in
            _ = try? await webView.evaluateJavaScript(js)
        }
    }
}
