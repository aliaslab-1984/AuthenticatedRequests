//
//  ARAuthenticator.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

public enum AuthenticatorError: Error, LocalizedError {
    case missingConfiguration
    case invalidClientCredentials
    case invalidScope
    
    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "The authenticator has not been configured with the authentication endpoint."
        case .invalidClientCredentials:
            return "The provided credentials are not valid."
        case .invalidScope:
            return "The provided scope, is not valid."
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
    private var currentToken: OAuth2Token = .init(access_token: "", refresh_token: nil, expires_in: 0, token_type: "bearer", creationDate: Date())
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
            
            let newToken = try await getNewToken()
            assignNewToken(newToken)
            return newToken
        }
        
        self.fetchTask = task
        
        return try await task.value
    }
    
    private func getNewToken() async throws -> OAuth2Token {
        
        let credentials = try await validateCredentials()
        if let refresh = currentToken.refresh_token {
            return try await refreshToken(refresh: refresh, clientId: credentials.clientID)
        } else {
            return try await authenticationEndpoint.request(using: credentials)
        }
    }
    
    public func refreshToken(refresh: String, clientId: String) async throws -> OAuth2Token {
        let flow = ARRefreshToken(clientID: clientId,
                                  clientSecret: "",
                                  refreshToken: refresh)
        return try await authenticationEndpoint.request(using: flow)
    }
    
    private func assignNewToken(_ token: OAuth2Token) {
        currentToken = token
        currentToken.date = Date()
        
        if !tokenStore.saveToken(token: token) {
            print("Failed to store token.")
        }
    }
    
}
