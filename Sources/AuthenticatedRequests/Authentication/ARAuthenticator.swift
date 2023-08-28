//
//  ARAuthenticator.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

public enum AuthenticatorError: Error, LocalizedError {
    
    case missingEnvironment
    case missingConfiguration
    case invalidClientCredentials
    case invalidScope
    case invalidAuthorizeUrl
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .missingEnvironment:
            return "The network environment has not been configured or is not valid."
        case .missingConfiguration:
            return "The authenticator has not been configured with the authentication endpoint."
        case .invalidClientCredentials:
            return "The provided credentials are not valid."
        case .invalidScope:
            return "The provided scope, is not valid."
        case .invalidAuthorizeUrl:
            return "Invalid authorization URL"
        case .unknown:
            return "Unknown error"
        }
    }
}

/**
 Atomic object that manages to refresh the OAuthToken when needed.
 It must be configured with a `OAuthFlow` in order to correctly fetch and save the `OAuthToken`s.
 */
public actor ARAuthenticator: Authenticator {
    
    public typealias ARConfiguration = OAuthFlow
    
    private var tokenStore: ARTokenManager
    private var currentToken = OAuth2Token.empty
    /**
     The task that is responsible for the fetch of a new access token or for a refresh.
     */
    private var fetchTask: Task<OAuth2Token, Error>?
    private var clientCredentials: ARConfiguration?
    
    /// The current authentication endpoint.
    public var authenticationEndpoint: AuthenticationEndpoint
    
    public init(tokenStore: ARTokenManager,
                baseEndpoint: AuthenticationEndpoint) {
        self.tokenStore = tokenStore
        self.authenticationEndpoint = baseEndpoint
    }
    
    /// Updates the current authentication endpoint with a new one.
    /// - Parameter authenticationEndpoint: The new authentication endpoint to be used.
    public func update(authenticationEndpoint: AuthenticationEndpoint) async {
        guard self.authenticationEndpoint != authenticationEndpoint else {
            return
        }
        self.authenticationEndpoint = authenticationEndpoint
    }
    
    /// Configures the authenticator with a new client credentials instance.
    /// This will trigger a override of the current token.
    ///
    /// If the privided `ClientCredentials` structure is the same as the current one, this method will do nothing.
    /// - Parameter parameter: The new client credentials instance that will replace the current one.
    public func configure(with parameter: ARConfiguration) async {
        
        guard !parameter.isEqualTo(otherFlow: clientCredentials) else {
            return
        }
        
        self.clientCredentials = parameter
        self.tokenStore.setPrefix(parameter.clientID)
        
        if let token = tokenStore.token(),
           let date = tokenStore.tokenDate() {
            self.currentToken = token
            self.currentToken.date = date
        } else {
            // We don't have saved any token for this client credentials, we need to fetch
            // a new token from the backend
            self.currentToken = .invalidToken
        }
    }
    
    public func tokenStore() async -> ARTokenManager {
        return self.tokenStore
    }
    
    public func configuration() async -> ARConfiguration? {
        return self.clientCredentials
    }
    
    public func validToken() async throws -> OAuth2Token {
        
        if let refreshTask = fetchTask {
            return try await refreshTask.value
        }
        
        let task = Task { () throws -> OAuth2Token in
            defer { self.fetchTask = nil }
            
            if self.currentToken.isValid {
                return currentToken
            }
            
            return try await getNewToken()
        }
        
        self.fetchTask = task
        
        return try await task.value
    }
    
    public func removeToken() -> Bool {
        
        currentToken = .empty
//        if let codeFlowCredentials = clientCredentials as? ARCodeFlow {
//            clientCredentials = ARCodeFlow(clientID: codeFlowCredentials.clientID,
//                                           code: "",
//                                           redirectUrl: codeFlowCredentials.redirectUrl,
//                                           codeVerifier: codeFlowCredentials.codeVerifier)
//        }
        clientCredentials = nil
        return tokenStore.removeToken()
    }
    
    private func getNewToken() async throws -> OAuth2Token {
        
        let credentials = try await validateCredentials()
        if let refresh = currentToken.refresh_token {
            do {
                print(">> REFRESH Token <<")
                return try await refreshToken(refresh: refresh, clientId: credentials.clientID)
            } catch {
                print(">> NEW Token <<")
                return try await newToken(credentials: credentials)
            }
        } else {
            return try await newToken(credentials: credentials)
        }
    }
    
    public func refreshToken(refresh: String, clientId: String) async throws -> OAuth2Token {
        let flow = ARRefreshToken(clientID: clientId,
                                  clientSecret: "",
                                  refreshToken: refresh)
        let newToken = try await authenticationEndpoint.request(using: flow)
        assignNewToken(newToken)
        return newToken
    }
    
    private func newToken(credentials: ARConfiguration) async throws -> OAuth2Token {
        let newToken = try await authenticationEndpoint.request(using: credentials)
        assignNewToken(newToken)
        return newToken
    }
    
    private func assignNewToken(_ token: OAuth2Token) {
        
        currentToken = token
        currentToken.date = Date()
        
        if !tokenStore.saveToken(token: token) {
            print("Failed to store token.")
        }
    }
    
}
