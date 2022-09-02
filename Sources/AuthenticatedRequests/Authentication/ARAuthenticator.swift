//
//  ARAuthenticator.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

enum AuthenticatorError: Error {
    case missingClientCredentials
    case invalidClientCredentials
    case invalidScope
}

/**
 Atomic object that manages to refresh the OAuthToken when needed.
 It must be configured with a `ClientCredentials` in order to correcly fetch and save the `OAuthToken`s.
 */
actor ARAuthenticator: Authenticator {
    
    typealias ARConfiguration = ARClientCredentials
    
    private var tokenStore: ARTokenManager
    private var currentToken: OAuth2Token = .init(access_token: "", refresh_token: nil, expires_in: 0, token_type: "bearer", creationDate: Date())
    /**
     The task that is responsible for the fetch of a new access token.
     */
    private var fetchTask: Task<OAuth2Token, Error>?
    private var clientCredentials: ARClientCredentials?
    
    private let authenticationEndpoint: AuthenticationEndpoint
    
    init(tokenStore: ARTokenManager, baseEndpoint: AuthenticationEndpoint) {
        self.tokenStore = tokenStore
        self.authenticationEndpoint = baseEndpoint
    }
    
    /// Configures the authenticator with a new client credentials instance.
    /// This will trigger a override of the current token.
    ///
    /// If the privided `ClientCredentials` structure is the same as the current one, this method will do nothing.
    /// - Parameter parameter: The new client credentials instance that will replace the current one.
    func configure(with parameter: ARConfiguration) async {
        
        guard parameter != clientCredentials else {
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
    
    func tokenStore() async -> ARTokenManager {
        return self.tokenStore
    }
    
    func configuration() async -> ARClientCredentials? {
        return self.clientCredentials
    }
    
    func validToken() async throws -> OAuth2Token {
        if let refreshTask = fetchTask {
            return try await refreshTask.value
        }
        
        let task = Task { () throws -> OAuth2Token in
            defer { self.fetchTask = nil }
            
            let credentials = try await self.validateCredentials()
            
            if self.currentToken.isValid {
                return currentToken
            }
            
            let newToken = try await authenticationEndpoint.request(using: credentials)
            
            assignNewToken(newToken)
            
            return newToken
        }
        
        self.fetchTask = task
        
        return try await task.value
    }
    
    private func assignNewToken(_ token: OAuth2Token) {
        currentToken.access_token = token.access_token
        currentToken.expires_in = token.expires_in
        currentToken.token_type = token.token_type
        if let refresh = token.refresh_token {
            currentToken.refresh_token = refresh
        }
        currentToken.date = Date()
        
        if !tokenStore.saveToken(token: token) {
            print("Failed to store token.")
        }
    }
    
}
