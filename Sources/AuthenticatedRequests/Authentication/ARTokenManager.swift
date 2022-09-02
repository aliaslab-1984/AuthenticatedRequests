//
//  ARTokenManager.swift
//
//
//  Created by Francesco Bianco on 13/01/22.
//

import Foundation
#if canImport(KeychainSwift)
import KeychainSwift

/**
 This class is responsible to maintain all the token for every user.
 Everytime the user changes, it's required to set the keyPrefix to the corresponding username or client ID.
 */
public final class ARTokenManager {
    
    private let keychain: TokenStore
    private var keyPrefix: String
    private let encoder: JSONEncoder = .init()
    private let decoder: JSONDecoder = .init()
    
    public init(keychain: TokenStore = KeychainSwift(),
                prefix: String = "") {
        self.keychain = keychain
        self.keyPrefix = prefix
    }
    
    public func setPrefix(_ prefix: String) {
        self.keyPrefix = prefix
    }
    
    public func saveToken(token: OAuth2Token) -> Bool {
        
        var success: Bool = true
        if !keychain.set(object: token,
                         forKey: KeychainKey.clientToken.prefixed(keyPrefix),
                         usingEncoder: encoder) {
            print("Unable to set new logged in token.")
            success = false
        }
        
        if !keychain.set(object: Date().timeIntervalSince1970,
                         forKey: KeychainKey.creationDate.prefixed(keyPrefix),
                         usingEncoder: encoder) {
            print("Unable to set new logged date.")
            success = false
        }
        
        print("Succeded to set new token for: \(keyPrefix)")
        
        return success
    }
    
    public func token() -> OAuth2Token? {
        return keychain.object(OAuth2Token.self,
                               with: KeychainKey.clientToken.prefixed(keyPrefix),
                               usingDecoder: decoder)
    }
    
    public func tokenDate() -> Date? {
        if let interval = keychain.object(TimeInterval.self,
                                          with: KeychainKey.creationDate.prefixed(keyPrefix),
                                          usingDecoder: decoder) {
            return Date(timeIntervalSince1970: interval)
        } else {
            return nil
        }
        
    }
    
    public func removeToken() -> Bool {
        var success: Bool = true
        
        if !keychain.delete(KeychainKey.clientToken.prefixed(keyPrefix)) {
            print("Unable to delete token for user \(keyPrefix).")
            success = false
        }
        
        if !keychain.delete(KeychainKey.clientToken.prefixed(keyPrefix)) {
            print("Unable to delete logged date for user \(keyPrefix).")
            success = false
        }
        
        print("Successfully removed token for: \(keyPrefix).")
        
        return success
    }
}

#endif

