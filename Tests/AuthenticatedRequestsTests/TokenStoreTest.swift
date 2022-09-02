//
//  File.swift
//  
//
//  Created by Francesco Bianco on 28/06/22.
//

import Foundation
import XCTest

@testable import AuthenticatedRequests

final class TokenStoreTest: XCTestCase {
    
    func testNonExistentToken() {
        
        let store = MockTokenStore()
        store.expectedToken = nil
        
        var token = store.object(OAuth2Token.self, with: "", usingDecoder: .init())
        
        XCTAssertNil(token)
        
        store.expectedToken = .invalidToken
        
        token = store.object(OAuth2Token.self, with: "", usingDecoder: .init())
        
        XCTAssertNotNil(token)
    }
}
