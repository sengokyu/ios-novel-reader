import WebKit

@MainActor
final class ReaderController {
    var onScrollChanged: ((Double) -> Void)?
    private var webView: WKWebView?
    private var isNavigationReady = false

    private var pendingContent: (html: String, offset: Double?)?
    private var pendingSettings: (fontSize: Int, lineHeight: Double, marginV: Int, marginH: Int, fontFamily: String)?

    func attach(_ webView: WKWebView) {
        self.webView = webView
        isNavigationReady = false
    }

    func navigationDidFinish() {
        isNavigationReady = true
        if let s = pendingSettings {
            pendingSettings = nil
            applySettings(fontSize: s.fontSize, lineHeight: s.lineHeight, marginV: s.marginV, marginH: s.marginH, fontFamily: s.fontFamily)
        }
        if let c = pendingContent {
            pendingContent = nil
            setContent(c.html, offset: c.offset)
        }
    }

    func setContent(_ html: String, offset: Double?) {
        guard let webView,
              let json = try? JSONEncoder().encode(html),
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
            _ = try? await self?.webView?.evaluateJavaScript("pageForward()")
        }
    }

    func pageBack() {
        Task { @MainActor [weak self] in
            _ = try? await self?.webView?.evaluateJavaScript("pageBack()")
        }
    }

    func applySettings(fontSize: Int, lineHeight: Double, marginV: Int, marginH: Int, fontFamily: String) {
        guard let webView,
              let ffJson = try? JSONEncoder().encode(fontFamily),
              let ffString = String(data: ffJson, encoding: .utf8) else { return }
        guard isNavigationReady else {
            pendingSettings = (fontSize, lineHeight, marginV, marginH, fontFamily)
            return
        }
        let js = "setStyles(\(fontSize), \(lineHeight), \(marginV), \(marginH), \(ffString))"
        Task { @MainActor in
            _ = try? await webView.evaluateJavaScript(js)
        }
    }
}
