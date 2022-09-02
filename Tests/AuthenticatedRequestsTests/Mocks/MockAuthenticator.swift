//
//  File.swift
//  
//
//  Created by Francesco Bianco on 28/06/22.
//

import Foundation

@testable import AuthenticatedRequests

final class MockAuthenticator: Authenticator {
    
    typealias ARConfiguration = ARClientCredentials
    private var tokenStore: ARTokenManager
    var configuration: ARConfiguration?
    var expectedToken: OAuth2Token?
    
    init(tokenStore: ARTokenManager = .init()) {
        self.tokenStore = tokenStore
    }
    
    func reset() {
        configuration = nil
    }
    
    func configure(with parameter: ARClientCredentials) async {
        
        guard configuration != parameter else {
            return
        }
        
        self.configuration = parameter
    }
    
    func tokenStore() async -> ARTokenManager {
        return self.tokenStore
    }
    
    func validToken() async throws -> OAuth2Token {
        _ = try await self.validateCredentials()
    
        if let storedToken = tokenStore.token() {
            return storedToken
        } else {
            if let expectedToken = expectedToken {
                return expectedToken
            } else {
                throw URLError(.badURL)
            }
        }
        
    }
    
    func configuration() async -> ARClientCredentials? {
        return self.configuration
    }
}
