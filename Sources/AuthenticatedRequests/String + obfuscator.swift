//
//  File.swift
//  
//
//  Created by Francesco Bianco on 22/07/22.
//

import Foundation

public extension String {
    
    // DeObfuscator
    func deobf() -> String? {
        
        var byteArray = [UInt8](self.exaToBytes())
        var xorel: UInt8 = 28
        for index in 0 ..< byteArray.count {
            byteArray[index] ^= xorel
            xorel += 1
        }
        return String(bytes: byteArray, encoding: .utf8)
    }
    
    // Obfuscator
    func obf() -> String {
        
        var byteArray: [UInt8] = Array(self.utf8)
        var xorel: UInt8 = 28
        for index in 0 ..< byteArray.count {
            byteArray[index] ^= xorel
            xorel += 1
        }
        
        let data = Data(byteArray)
        let hexString = data.map { String(format: "%02X", $0) }.joined()
        return hexString
    }
    
    /// Convert hex string to bytes
    private func exaToBytes() -> Data {
        
        var exa = self
        if exa.count % 2 != 0 {
            exa += "0"
        }
        let half = exa.count / 2
        var dataRet = Data(capacity: half)
        for index in 0 ..< half {
            
            let start = exa.index(exa.startIndex, offsetBy: index * 2)
            let end = exa.index(exa.startIndex, offsetBy: index * 2 + 2)
            let range = start..<end
            let hexString = exa[range]
            
            if let num = UInt8(hexString, radix: 16) {
                dataRet.append(num)
            } else {
                dataRet.append(0)
            }
        }
        return dataRet
    }
}
