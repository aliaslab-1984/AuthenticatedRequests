//
//  File.swift
//  
//
//  Created by Francesco Bianco on 27/06/22.
//

import Foundation

// MARK: -Authenticator

/**
 An object that is capable to authenticate a request based on a ARConfiguration.
 */
public protocol Authenticator {
    
    associatedtype ARConfiguration
    
    /**
     Returns the current `ARTokenStore` that is used to manage the stored auth tokens.
     */
    func tokenStore() async -> ARTokenManager
    
    /**
     Configures the authenticator with a new parameter.
     */
    func configure(with parameter: ARConfiguration) async
    
    /**
     The current configuration that is held by the authenticator.
     - Returns The current configuration.
     */
    func configuration() async -> ARConfiguration?
    
    /**
     Asynchronously returns a valid token if exists.
     */
    func validToken() async throws -> OAuth2Token
    
}

public extension Authenticator where ARConfiguration == ARClientCredentials {
    
    /**
     Given the current credentials (returned by the `configuration()`), this method does a validation, to ensure that they satisfy some minimum requirements.
     For example, not being nil or having all the fields non empty.
     */
    func validateCredentials() async throws -> ARConfiguration {
        async let configuration = configuration()
        guard let clientCredentials = await configuration else {
            throw AuthenticatorError.missingClientCredentials
        }
        
        guard !clientCredentials.clientID.isEmpty ||
                !clientCredentials.clientSecret.isEmpty else {
            throw AuthenticatorError.invalidClientCredentials
        }
        
//        guard !clientCredentials.scope.isEmpty else {
//            throw AuthenticatorError.invalidScope
//        }
        
        return clientCredentials
    }
    
}

// -MARK: AnyAuthenticator

/**
 A type eraser that helps to store a generic Authenticator instance.
 */
public struct AnyAuthenticator<A>: Authenticator {
    
    public typealias ARConfiguration = A
    
    public func tokenStore() async -> ARTokenManager {
        return await onStore.value
    }

    private var onConfigure: ((A) -> Void)?
    private var onValidToken: Task<OAuth2Token, Error>?
    private var onConfiguration: Task<A?, Never>?
    private var onStore: Task<ARTokenManager, Never>
   
    public init<Auth: Authenticator>(_ authenticator: Auth) where Auth.ARConfiguration == A {
        self.onConfigure = { configuration in
            Task {
                await authenticator.configure(with: configuration)
            }
        }
        
        self.onStore = Task {
            return await authenticator.tokenStore()
        }
        
        self.onConfiguration = Task {
            return await authenticator.configuration()
        }
        
        self.onValidToken = Task {
            return try await authenticator.validToken()
        }
    }
    
    public func configure(with parameter: A) async {
        onConfigure?(parameter)
    }
    
    public func configuration() async -> A? {
        return await onConfiguration?.value
    }
    
    public func validToken() async throws -> OAuth2Token {
        return try await onValidToken?.value ?? OAuth2Token.invalidToken
    }
    
}
