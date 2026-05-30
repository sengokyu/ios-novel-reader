import WebKit

@MainActor
final class ReaderController {
    var onScrollChanged: ((Double) -> Void)?
    private var webView: WKWebView?

    func attach(_ webView: WKWebView) {
        self.webView = webView
    }

    func setContent(_ html: String, offset: Double?) {
        guard let webView,
              let json = try? JSONSerialization.data(withJSONObject: html),
              let jsonString = String(data: json, encoding: .utf8) else { return }
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
}
