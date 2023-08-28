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
    
    public enum LoginError: Error, LocalizedError {
        // Initial login
        case badLoginURL
        case badRedirectURI
        // Response from the initial login
        case missingQueryItems
        case missingState
        case missingCode
        case stateMismatch
        case unknownCodeFlow
        
        public var errorDescription: String? {
            switch self {
            case .badLoginURL:
                return "The provided login url, is not valid."
            case .badRedirectURI:
                return "The provided redirect uri, is not valid."
            case .missingQueryItems:
                return "Missing some components for the login."
            case .missingState:
                return "No state has been provided."
            case .missingCode:
                return "No code has been provided."
            case .stateMismatch:
                return "The two states doesn't match with each other."
            case .unknownCodeFlow:
                return "The code flow is unknown."
            }
        }
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
        
<<<<<<< HEAD
        if let codeFlowConfiguration = configuration.codeFlowConfiguration as? CodeFlowConfiguration {
            return try handleCodeFlowResult(for: codeFlowConfiguration, with: items)
=======
        if let standard = configuration.codeFlowConfiguration as? BasicCodeFlowConfiguration {
            return try handleCodeFlowResult(for: standard, with: items)
        } else {
            throw LoginError.unknownCodeFlow
        }
    }
}

private extension CodeFlowManager {
    
    func handleCodeFlowResult(for configuration: BasicCodeFlowConfiguration,
                              with items: [URLQueryItem]) throws -> String {
        
        guard let receivedState = getItemValue(name: "state", from: items) else {
            throw LoginError.missingState
        }
        
        guard let receivedCode = getItemValue(name: "code", from: items) else {
            throw LoginError.missingCode
        }
        
        guard receivedState == configuration.state else {
            throw LoginError.stateMismatch
        }
        
        return receivedCode
    }
    
    private func getItemValue(name: String, from items: [URLQueryItem]) -> String? {
        
        guard let item = items.first(where: { $0.name == name }),
              let value = item.value,
              !value.isEmpty
        else { return nil }
        
        return value
    }
}


