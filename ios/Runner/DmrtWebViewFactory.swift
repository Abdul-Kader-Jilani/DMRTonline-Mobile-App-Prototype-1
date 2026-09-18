import Flutter
import UIKit
import WebKit

class DmrtWebViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return DmrtWebView(frame: frame)
  }
}

private class DmrtWebView: NSObject, FlutterPlatformView {
  private let webView: WKWebView

  init(frame: CGRect) {
    let configuration = WKWebViewConfiguration()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    configuration.allowsInlineMediaPlayback = true

    webView = WKWebView(frame: frame, configuration: configuration)
    webView.scrollView.bounces = false
    webView.scrollView.showsVerticalScrollIndicator = false
    webView.scrollView.showsHorizontalScrollIndicator = false
    webView.isOpaque = false
    webView.backgroundColor = UIColor(red: 0.969, green: 0.984, blue: 0.976, alpha: 1.0)

    super.init()
    loadPrototype()
  }

  func view() -> UIView {
    return webView
  }

  private func loadPrototype() {
    if let appFramework = Bundle.main.url(
      forResource: "App",
      withExtension: "framework",
      subdirectory: "Frameworks"
    ),
      let appBundle = Bundle(url: appFramework),
      let indexUrl = appBundle.url(
        forResource: "index",
        withExtension: "html",
        subdirectory: "flutter_assets/assets"
      ) {
      let baseUrl = indexUrl.deletingLastPathComponent()
      webView.loadFileURL(indexUrl, allowingReadAccessTo: baseUrl)
    }
  }
}
