//
//  File.swift
//  
//
//  Created by Francesco Bianco on 28/06/22.
//

import Foundation
import XCTest

@testable import AuthenticatedRequests

final class AuthenticatorTest: XCTestCase {
    
    private static let expectedValidToken = OAuth2Token(access_token: "new_token", refresh_token: nil, expires_in: 3600, token_type: "bearer", creationDate: Date())
    private var authenticator: MockAuthenticator = .init()
    
    override func setUp() {
        authenticator.reset()
    }
    
    // - MARK: Wrong ClientCredentials
    
    func testAuthenticator() async throws {
        let credentials = ARClientCredentials(clientID: "", clientSecret: "", scope: Set([]))
        await authenticator.configure(with: credentials)
        XCTAssertEqual(authenticator.configuration, credentials)
    }
    
    func testMissingCredentials() async throws {
        do {
            _ = try await authenticator.validToken()
        } catch {
            error.mapAuthenticationError(with: .missingClientCredentials)
        }
    }
    
    func testInvalidCredentials() async throws {
        let credentials = ARClientCredentials(clientID: "", clientSecret: "", scope: Set([]))
        await authenticator.configure(with: credentials)
        do {
            _ = try await authenticator.validToken()
        } catch {
            error.mapAuthenticationError(with: .invalidClientCredentials)
        }
    }
    
    func testInvalidScope() async throws {
        let credentials = ARClientCredentials(clientID: "Ciao", clientSecret: "Ciao ciao", scope: Set([]))
        await authenticator.configure(with: credentials)
        do {
            _ = try await authenticator.validToken()
        } catch {
            error.mapAuthenticationError(with: .invalidScope)
        }
    }
    
    func testValidCredentials() async throws {
        let authenticator = await validAuthenticator()
        authenticator.expectedToken = Self.expectedValidToken
        let token = try await authenticator.validToken()
        XCTAssertNotEqual(token, .invalidToken)
    }
    
    // - MARK: Interaction with ARTokenStore
    
    func testInteractionWithNoToken() async throws {
        let mockKeychain = MockTokenStore()
        let store = ARTokenManager(keychain: mockKeychain)
        mockKeychain.expectedToken = nil
        let authenticator = await validAuthenticator(with: store)
        authenticator.expectedToken = Self.expectedValidToken
        let token = try await authenticator.validToken()
        XCTAssertEqual(token.access_token, "new_token")
    }
    
    func testInteractionWithToken() async throws {
        let mockKeychain = MockTokenStore()
        let store = ARTokenManager(keychain: mockKeychain)
        mockKeychain.expectedToken = OAuth2Token(access_token: "expected", refresh_token: nil, expires_in: 3600, token_type: "bearer", creationDate: .init())
        let authenticator = await validAuthenticator(with: store)
        let token = try await authenticator.validToken()
        XCTAssertEqual(token.access_token, "expected")
    }
    
    func testErrorWhileFetchingToken() async throws {
        let mockKeychain = MockTokenStore()
        let store = ARTokenManager(keychain: mockKeychain)
        mockKeychain.expectedToken = nil
        let authenticator = await validAuthenticator(with: store)
        do {
            let token = try await authenticator.validToken()
            XCTAssertNotEqual(token, .invalidToken)
        } catch {
            XCTAssertEqual(1, 1)
        }
    }
    
    func testGetToken() async throws {
        let authenticator = ARAuthenticator(tokenStore: .init(), baseEndpoint: AuthenticationEndpoint(baseEndpoint: URL(staticString: "https://api.redgifs.com"), path: "example"))
        let client = ARClientCredentials(clientID: "esempio", clientSecret: "esempio", scope: Set([]))
        await authenticator.configure(with: client)
        
        do {
            let token = try await authenticator.validToken()
            XCTAssertNotEqual(token, .invalidToken)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

private extension AuthenticatorTest {
    
    func validAuthenticator(with store: ARTokenManager? = nil) async -> MockAuthenticator {
        let authenticator: MockAuthenticator
        if let store = store {
            authenticator = .init(tokenStore: store)
        } else {
            authenticator = .init()
        }
        let credentials = ARClientCredentials(clientID: "Ciao", clientSecret: "Ciao ciao", scope: Set(["example"]))
        await authenticator.configure(with: credentials)
        
        return authenticator
    }
    
}

extension Error {
    
    func mapAuthenticationError(with expectedError: AuthenticatorError) {
        if let error = self as? AuthenticatorError {
            XCTAssertEqual(error, expectedError)
        }
    }
    
}
