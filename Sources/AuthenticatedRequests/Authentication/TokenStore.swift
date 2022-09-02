//
//  File.swift
//  
//
//  Created by Francesco Bianco on 28/06/22.
//

import Foundation

/**
 An object that is required to store, manage and return codable oject into a safe box.
 */
protocol TokenStore {
    
    func object<T: Codable>(_ type: T.Type,
                            with key: String,
                            usingDecoder decoder: JSONDecoder) -> T?
    
    func set<T: Codable>(object: T?,
                         forKey key: String,
                         usingEncoder encoder: JSONEncoder) -> Bool
    
    @discardableResult
    func delete(_ key: String) -> Bool
    
}

#if canImport(KeychainSwift)
import KeychainSwift

extension KeychainSwift: TokenStore {
    
}

#endif
