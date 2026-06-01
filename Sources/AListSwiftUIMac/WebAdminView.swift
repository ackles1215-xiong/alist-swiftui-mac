import SwiftUI
import WebKit

struct WebAdminView: NSViewRepresentable {
    let url: URL?

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        return WKWebView(frame: .zero, configuration: configuration)
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let url else {
            webView.loadHTMLString(emptyStateHTML, baseURL: nil)
            return
        }

        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    private var emptyStateHTML: String {
        """
        <!doctype html>
        <html>
          <body style="font: -apple-system-body; color: #777; display: grid; place-items: center; height: 100vh;">
            <div>Start AList to load the admin interface.</div>
          </body>
        </html>
        """
    }
}
