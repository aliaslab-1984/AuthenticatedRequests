//
//  File.swift
//  
//
//  Created by Francesco Bianco on 28/06/22.
//

import Foundation

@testable import AuthenticatedRequests

final class MockTokenStore: TokenStore {
    
    init(_ token: OAuth2Token? = nil,
         expectedDate: Date? = nil) {
        self.expectedToken = token
        self.expectedDate = expectedDate
    }
    
    var expectedToken: OAuth2Token?
    var expectedDate: Date?
    
    func object<T>(_ type: T.Type,
                   with key: String,
                   usingDecoder decoder: JSONDecoder) -> T? where T : Decodable, T : Encodable {
        
        if type == OAuth2Token.self {
            return expectedToken as? T
        } else {
            return expectedDate as? T
        }
    }
    
    func set<T>(object: T?,
                forKey key: String,
                usingEncoder encoder: JSONEncoder) -> Bool where T : Decodable, T : Encodable {
        true
    }
    
    func delete(_ key: String) -> Bool {
        true
    }
    
}
