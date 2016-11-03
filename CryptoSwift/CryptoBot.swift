//
//  CryptoBot.swift
//  Beloved Robot
//
//  Created by Zane Kellogg on 1/18/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation
import CryptoSwift

public class CryptoBot {
    
    private let key : String = "53a738e847f63b92"
    private let iv : String = "3ac8fd8cb2a87e56"
    
    // Test Vectors (http://www.inconteam.com/software-development/41-encryption/55-aes-test-vectors#aes-cbc-256)
    //    private let key : String = "603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"
    //    private let iv : String = "000102030405060708090A0B0C0D0E0F"
    //    private let secret : String = "6bc1bee22e409f96e93d7e117393172a"
    //    private let cipher : String = "f58c4c04d6e5f1ba779eabfb5f7bfbd6"
    
    func encrypt(secret : String) throws -> String {
        let secretInput = secret.utf8.map({$0})
        let encrypted: [UInt8] = try AES(key: key, iv: iv, blockMode: .CBC).encrypt(secretInput)
        if let cipher = encrypted.toBase64() {
            return cipher
        }
        return ""
    }
    
    func decrypt(cipher : String) throws -> String {
        let aes = try AES(key: key, iv: iv, blockMode: .CBC)
        let secret = try cipher.decryptBase64ToString(cipher: aes)
        return secret
    }
    
    //    func byteArrayToBase64(bytes: [UInt8]) -> String {
    //        let nsdata = NSData(bytes: bytes, length: bytes.count)
    //        let base64Encoded = nsdata.base64EncodedStringWithOptions([]);
    //        return base64Encoded;
    //    }
    //
    //    func base64ToByteArray(base64String: String) -> [UInt8]? {
    //        if let nsdata = NSData(base64EncodedString: base64String, options: []) {
    //            var bytes = [UInt8](count: nsdata.length, repeatedValue: 0)
    //            nsdata.getBytes(&bytes, length: bytes.count)
    //            return bytes
    //        }
    //        return nil // Invalid input
    //    }
}