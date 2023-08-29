//
//  LoginWebViewController.swift
//  
//
//  Created by Francesco Bianco on 27/02/23.
//

import Foundation
import WebKit

#if canImport(UIKit)
import UIKit

public final class LoginWebViewController: UIViewController, WKNavigationDelegate {
    
    private lazy var webView: WKWebView = { [unowned self] in
        let webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()
    
    private let initialURL: URL
    private let redirectURLIntercept: URL
    private let redirectURLInterceptor: (URL) -> Void
    
    public init(initialURL: URL,
                redirectURLIntercept: URL,
                onIntercept: @escaping (URL) -> Void) {
        
        self.initialURL = initialURL
        self.redirectURLIntercept = redirectURLIntercept
        self.redirectURLInterceptor = onIntercept
        super.init(nibName: nil, bundle: nil)
        
        LoginWebViewController.clearCache()
        LoginWebViewController.clearCookies()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        super.loadView()
        
        self.view.addSubview(webView)
        
        let constraints: [NSLayoutConstraint] = [
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.load(URLRequest(url: initialURL))
    }
}

public extension LoginWebViewController {
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // here we handle internally the callback url and call method that call handleOpenURL
        // **(no app scheme is used because the infrastructure is dog shit)**.
        debugPrint("🔰🔰", navigationAction.request.url ?? "--")
        if let url = navigationAction.request.url,
           matchesInterceptorURL(url) {
            
            debugPrint("Matched the intercept url")
            redirectURLInterceptor(url)
            decisionHandler(.cancel)

            view.endEditing(true)
            return
        }

        decisionHandler(.allow)
    }
    
}

private extension LoginWebViewController {
    
    func matchesInterceptorURL(_ url: URL) -> Bool {
        return url.scheme == redirectURLIntercept.scheme &&
               url.host == redirectURLIntercept.host
    }
    
    static func clearCache() {
        
        URLCache.shared.removeAllCachedResponses()
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0),
            completionHandler:{})
    }
    
    static func clearCookies() {
        
        for cookie in HTTPCookieStorage.shared.cookies ?? [] {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
}

#endif

