//
//  File.swift
//  
//
//  Created by Francesco Bianco on 20/07/22.
//

import Foundation
import XCTest

@testable import AuthenticatedRequests

final class ConfigurationTest: XCTestCase {
    
    var token: OAuth2Token?
    var keychain = MockTokenStore()
    lazy var authenticator: ARAuthenticator = {
        ARAuthenticator(tokenStore: ARTokenManager(keychain: self.keychain), baseEndpoint: URL(staticString: "https:/api.redgifs.com"))
    }()
    
    let client = ARClientCredentials(clientID: "esempio", clientSecret: "esempio", scope: Set([]))
    
    override func setUp() async throws {
        if token == nil {
            let client = ARClientCredentials(clientID: "esempio", clientSecret: "esempio", scope: Set([]))
            await authenticator.configure(with: client)
            
            let token = try await authenticator.validToken()
            XCTAssertNotEqual(token, .invalidToken)
            self.token = token
            self.keychain.expectedDate = Date()
            self.keychain.expectedToken = token
        }
    }
}
