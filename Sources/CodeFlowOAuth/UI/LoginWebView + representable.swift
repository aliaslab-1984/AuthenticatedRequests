//
//  LoginView.swift
//  
//
//  Created by Francesco Bianco on 27/02/23.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct LoginWebView: UIViewControllerRepresentable {
    
    public typealias UIViewControllerType = LoginWebViewController
    
    private let initialURL: URL
    private let redirectURLIntercept: URL
    private let redirectURLInterceptor: (URL) -> Void
    
    public init(initialURL: URL,
                redirectURLIntercept: URL,
                redirectURLInterceptor: @escaping (URL) -> Void) {
        self.initialURL = initialURL
        self.redirectURLIntercept = redirectURLIntercept
        self.redirectURLInterceptor = redirectURLInterceptor
    }
    
    public init(codeflowManager: CodeFlowManager) {
        let url = URL(string: codeflowManager.configuration.redirectURI)!
        self.redirectURLIntercept = url
        self.initialURL = try! codeflowManager.authorizeURL()
        self.redirectURLInterceptor = { interceptedUrl in
            let components = URLComponents(url: interceptedUrl, resolvingAgainstBaseURL: false)
            guard let items = components?.queryItems,
                  !items.isEmpty else {
                return
            }
            
            do {
                let activationCode = try codeflowManager.handleResponse(for: items)
                codeflowManager.responseCode = activationCode
            } catch {
                print(error)
            }
        }
    }
    
    public func makeUIViewController(context: Context) -> LoginWebViewController {
        return LoginWebViewController(initialURL: initialURL,
                                      redirectURLIntercept: redirectURLIntercept,
                                      onIntercept: redirectURLInterceptor)
    }
    
    public func updateUIViewController(_ uiViewController: LoginWebViewController,
                                       context: Context) {
        
    }
    
}

#endif
