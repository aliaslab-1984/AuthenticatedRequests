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
    
    public init?(codeflowManager: CodeFlowManager) {
        
        guard let url = URL(string: codeflowManager.configuration.redirectURI),
              let initial = try? codeflowManager.authorizeURL() else {
                  return nil
              }
        
        redirectURLIntercept = url
        initialURL = initial
        redirectURLInterceptor = { interceptedUrl in
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
    
    public func makeUIViewController(context: Context) -> UIViewControllerType {
        return LoginWebViewController(initialURL: initialURL,
                                      redirectURLIntercept: redirectURLIntercept,
                                      onIntercept: redirectURLInterceptor)
    }
    
    public func updateUIViewController(_ uiViewController: UIViewControllerType,
                                       context: Context) {
        
    }
}

#endif
