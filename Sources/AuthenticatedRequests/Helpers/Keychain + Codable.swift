//
//  Keychain + Codable.swift
//
//  Created by Francesco Bianco on 11/11/2019.
//  Copyright © 2019 Francesco Bianco. All rights reserved.
//

import Foundation
#if canImport(KeychainSwift)
import KeychainSwift

public extension KeychainSwift {
    
    func object<T: Codable>(_ type: T.Type, with key: String, usingDecoder decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let data = self.getData(key) else { return nil }
        return try? decoder.decode(type.self, from: data)
    }
    
    func set<T: Codable>(object: T?, forKey key: String, usingEncoder encoder: JSONEncoder = JSONEncoder()) -> Bool {
        guard let object = object else {
            return self.delete(key)
        }

        guard let data = try? encoder.encode(object) else { return false }
        return self.set(data, forKey: key, withAccess: .accessibleAfterFirstUnlock)
    }
}
#endif
