import SwiftUI
import WebKit

// Shows the WKWebView that ReaderController already created and pre-warmed.
struct ReaderWebView: UIViewRepresentable {
    let controller: ReaderController

    func makeUIView(context: Context) -> WKWebView {
        controller.webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
