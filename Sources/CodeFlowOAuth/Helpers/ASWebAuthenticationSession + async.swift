//
//  ASWebAuthenticationSession + async.swift
//  
//
//  Created by Francesco Bianco on 27/02/23.
//

import Foundation
import AuthenticationServices

extension ASWebAuthenticationSession {

    static func newASWebAuthenticationSession(url: URL, callbackURLScheme: String?) async throws -> URL {

        var interceptor: ((URL?, Error?) -> Void)?
        var session: ASWebAuthenticationSession?
        let onCancel = { session?.cancel() }

        return try await withTaskCancellationHandler {
            session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { url, error in
                interceptor?(url, error)
            }
            session?.start()
            
            return try await withCheckedThrowingContinuation { continuation in
                
                interceptor = { url, error in
                    if let error {
                        continuation.resume(with: .failure(error))
                    }
                    
                    if let url {
                        continuation.resume(with: .success(url))
                    }
                }
            }
        } onCancel: {
            onCancel()
        }
    }

}
