//
//  LoginManager.swift
//  
//
//  Created by Francesco Bianco on 24/02/23.
//

import Foundation
import SafariServices
import Combine
import AuthenticationServices

public final class CodeFlowManager {
    
    public enum LoginError: Error {
        // Initial login
        case badLoginURL
        case badRedirectURI
        // Response from the initial login
        case missingQueryItems
        case missingState
        case missingCode
        case stateMismatch
        case unknownCodeFlow
    }
    
    let configuration: AuthenticationConfiguration
    
    @Published public var responseCode: String?
    
    public init(configuration: AuthenticationConfiguration) {
        self.configuration = configuration
    }
    
    public func startSignIn() async throws -> String {
        
        // We need to check the redirect uri scheme, since
        // ASWebAuthenticationSession crashes if the provided uri starts with https/http.
        // This happens because it's a good practice to register a custom scheme for your app
        // Instead of having an http page..
        let redirectURL = URL(string: configuration.redirectURI)
        if let scheme = redirectURL?.scheme,
           scheme == "https" || scheme == "http" {
            throw LoginError.badRedirectURI
        }
        
        let url = try authorizeURL()
        
        let resultingURL = try await ASWebAuthenticationSession.newASWebAuthenticationSession(url: url, callbackURLScheme: configuration.redirectURI)
        
        let resultingURLComponents = URLComponents(url: resultingURL, resolvingAgainstBaseURL: true)
        guard let queryItems = resultingURLComponents?.queryItems,
              !queryItems.isEmpty else {
            throw LoginError.missingQueryItems
        }
        
        return try handleResponse(for: queryItems)
    }
    
    public func authorizeURL() throws -> URL {
        let components = configuration.codeFlowConfiguration.queryParameters
        
        var urlComponents = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: true)
        
        let queryComponents: [URLQueryItem] = configuration.queryItems + components
        
        urlComponents?.queryItems = queryComponents

        guard let url = urlComponents?.url else {
            throw LoginError.badLoginURL
        }
        
        return url
    }
    
    func handleResponse(for items: [URLQueryItem]) throws -> String {
        
        if let standard = configuration.codeFlowConfiguration as? BasicCodeFlowConfiguration {
            return try handleStandardCodeFlowResult(for: standard, with: items)
        } else if let pkceConfiguration = configuration.codeFlowConfiguration as? PKCECodeFlowConfiguration {
            return try handlePKCECodeFlowResult(for: pkceConfiguration, with: items)
        } else {
            throw LoginError.unknownCodeFlow
        }
    }
}

private extension CodeFlowManager {
    
    func handleStandardCodeFlowResult(for configuration: BasicCodeFlowConfiguration,
                                      with items: [URLQueryItem]) throws -> String {
        guard let receivedStateItem = items.first(where: { $0.name == "state" }),
              let receivedState = receivedStateItem.value,
              !receivedState.isEmpty
        else {
            throw LoginError.missingState
        }
        
        guard let receivedCodeItem = items.first(where: { $0.name == "code"}),
              let receivedCode = receivedCodeItem.value,
            !receivedCode.isEmpty
        else {
            throw LoginError.missingCode
        }
        
        guard receivedState == configuration.state else {
            throw LoginError.stateMismatch
        }
        
        return receivedCode
    }
    
    func handlePKCECodeFlowResult(for configuration: PKCECodeFlowConfiguration,
                                    with items: [URLQueryItem]) throws -> String {
        guard let receivedStateItem = items.first(where: { item in
            item.name == "state"
        }),
              let receivedState = receivedStateItem.value,
              !receivedState.isEmpty
        else {
            throw LoginError.missingState
        }
        
        guard let receivedCodeItem = items.first(where: { item in
            item.name == "code"
        }), let receivedCode = receivedCodeItem.value,
            !receivedCode.isEmpty
        else {
            throw LoginError.missingCode
        }
        
        guard receivedState == configuration.state else {
            throw LoginError.stateMismatch
        }
        
        return receivedCode
    }
}


