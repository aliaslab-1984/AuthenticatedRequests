//
//  File.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

protocol Prefixable: RawRepresentable {
    func prefixed(_ value: String) -> String
}

extension Prefixable where RawValue == String {
    
    func doPrefix(prefix: String) -> String {
        return prefix + self.rawValue
    }
    
}

public enum KeychainKey: String, Prefixable {
    
    case clientToken
    case creationDate = "creationDate"

    func prefixed(_ value: String) -> String {
        return doPrefix(prefix: value)
    }
}

