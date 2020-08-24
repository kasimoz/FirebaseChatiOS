//
//  AESEncryption.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 5.08.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import CommonCrypto

extension Data {
    func createKey(saltData: Data) -> Data {
        let length = kCCKeySizeAES256
        var status = Int32(0)
        var derivedBytes = [UInt8](repeating: 0, count: length)
        self.withUnsafeBytes{ (passwordBytes : UnsafeRawBufferPointer) in
            let passwordPointer: UnsafeRawPointer? = passwordBytes.baseAddress
            let password = passwordPointer?.assumingMemoryBound(to: Int8.self)
            saltData.withUnsafeBytes{ (saltBytes : UnsafeRawBufferPointer) in
                let saltPointer: UnsafeRawPointer? = saltBytes.baseAddress
                let salt = saltPointer?.assumingMemoryBound(to: UInt8.self)
                status = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),                  // algorithm
                    password,                                // password
                    self.count,                               // passwordLen
                    salt,                                    // salt
                    saltData.count,                                   // saltLen
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),   // prf
                    5000,                                        // rounds
                    &derivedBytes,                                // derivedKey
                    derivedBytes.count)                                       // derivedKeyLen
            }
        }
        
        
        if(status != kCCSuccess){
            return Data.init(count: 0)
        }
        return Data(bytes: derivedBytes, count: length)
    }
}

extension String {
    
    func aesEncrypt(key:String = "tK5UTui+DPh8lIlBxya5XVsmeDCoUl6vHhdIESMB6sQ=", salt:String = "QWlGNHNhMTJTQWZ2bGhpV3U=", iv:String = "bVQzNFNhRkQ1Njc4UUFaWA==") -> String? {
        if let keyData = key.data(using: String.Encoding.utf8)?.createKey(saltData: Data.init(base64Encoded: salt, options: .ignoreUnknownCharacters)!),
            let data = self.data(using: String.Encoding.utf8),
            let ivData = Data.init(base64Encoded: iv, options: .ignoreUnknownCharacters),
            let cryptData    = NSMutableData(length: Int((data.count)) + kCCKeySizeAES256) {
            
            let operation: CCOperation = UInt32(kCCEncrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
            let options:   CCOptions   = UInt32(kCCOptionPKCS7Padding)
            
            var numBytesEncrypted :size_t = 0
            var cryptStatus: CCCryptorStatus = CCCryptorStatus(kCCSuccess)
            ivData.withUnsafeBytes{ (ivBytes : UnsafeRawBufferPointer) in
                let ivPointer: UnsafeRawPointer? = ivBytes.baseAddress
                let iv = ivPointer?.assumingMemoryBound(to: UInt8.self)
                cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      (keyData as NSData).bytes, keyData.count,
                                      iv,
                                      (data as NSData).bytes, data.count,
                                      cryptData.mutableBytes, cryptData.length,
                                      &numBytesEncrypted)
            }
            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let base64cryptString = cryptData.base64EncodedString(options: .lineLength64Characters)
                return base64cryptString
                
            }
            else {
                return nil
            }
        }
        return nil
    }
    
    func aesDecrypt(key:String = "tK5UTui+DPh8lIlBxya5XVsmeDCoUl6vHhdIESMB6sQ=", salt:String = "QWlGNHNhMTJTQWZ2bGhpV3U=", iv:String = "bVQzNFNhRkQ1Njc4UUFaWA==") -> String? {
        if let keyData = key.data(using: String.Encoding.utf8)?.createKey(saltData: Data.init(base64Encoded: salt, options: .ignoreUnknownCharacters)!),
            let data = NSData(base64Encoded: self, options: .ignoreUnknownCharacters),
            let ivData = Data.init(base64Encoded: iv, options: .ignoreUnknownCharacters),
            let cryptData    = NSMutableData(length: Int((data.length)) + kCCKeySizeAES256) {
            
            let operation: CCOperation = UInt32(kCCDecrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
            let options:   CCOptions   = UInt32(kCCOptionPKCS7Padding)
            
            var numBytesEncrypted :size_t = 0
            var cryptStatus: CCCryptorStatus = CCCryptorStatus(kCCSuccess)
            
            ivData.withUnsafeBytes{ (ivBytes : UnsafeRawBufferPointer) in
                let ivPointer: UnsafeRawPointer? = ivBytes.baseAddress
                let iv = ivPointer?.assumingMemoryBound(to: UInt8.self)
                cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      (keyData as NSData).bytes, keyData.count,
                                      iv,
                                      data.bytes, data.length,
                                      cryptData.mutableBytes, cryptData.length,
                                      &numBytesEncrypted)
            }
            
            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let unencryptedMessage = String(data: cryptData as Data, encoding:String.Encoding.utf8)
                return unencryptedMessage
            }
            else {
                return nil
            }
        }
        return nil
    }
}

