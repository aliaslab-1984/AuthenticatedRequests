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
    }
    
    public convenience init(codeFlow: CodeFlowManager) {
        // TODO: find a way to unwrap
        let url = URL(string: codeFlow.configuration.redirectURI)!
        let initial = try! codeFlow.authorizeURL()
        self.init(initialURL: initial,
                  redirectURLIntercept: url) { interceptedUrl in
            let components = URLComponents(url: interceptedUrl, resolvingAgainstBaseURL: false)
            guard let items = components?.queryItems,
                  !items.isEmpty else {
                return
            }
            
            do {
                let activationCode = try codeFlow.handleResponse(for: items)
                codeFlow.responseCode = activationCode
            } catch {
                print(error)
            }
        }
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
    
}

#endif

