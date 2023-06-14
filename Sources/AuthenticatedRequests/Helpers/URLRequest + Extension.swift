//
//  URLRequest+extension.swift
//  Teamsystem Signature 2.0
//
//  Created by Enrico on 14/06/23.
//

import Foundation

extension URLRequest {
    
    public func debug() {
#if DEBUG
        print("== 🔎 URLRequest 🔍 \(String(repeating: "=", count: 80 - 20))")
        print(asCurl)
        print(String(repeating: "=", count: 80))
#endif
    }
    
    public var asCurl: String {
        
        guard let url else {
            return ""
        }
        
        var cUrlRepresentation = "curl -v -X \(httpMethod ?? "Unknown") \\\n"
        
        allHTTPHeaderFields?.forEach({ touple in
            cUrlRepresentation.append("-H \"\(touple.key): \(touple.value)\" \\\n")
        })
        
        if let httpBody,
           let stringBody = String(data: httpBody, encoding: .utf8) {
            cUrlRepresentation += "-d \"\(stringBody)\" \\\n"
        }
        
        cUrlRepresentation += url.absoluteString
        
        return cUrlRepresentation
    }
}
