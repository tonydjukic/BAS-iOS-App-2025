//
//  basiOS_KeychainHelper.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-04-30.
//

import Foundation
import Security
import os.log

struct basiOS_KeychainHelper {
    /// Save data to the keychain
    @discardableResult
    static func basiOS_save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock // Updated Accessibility
        ]
        
        SecItemDelete(query as CFDictionary) // Remove any existing item with the same key
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            os_log("Failed to save keychain item for key %{public}@. Status: %d", log: OSLog.keychain, type: .error, key, status)
        }
        
        return status == errSecSuccess
    }
    
    /// Load data from the keychain
    static func basiOS_load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status != errSecSuccess {
            os_log("Failed to load keychain item for key %{public}@. Status: %d", log: OSLog.keychain, type: .error, key, status)
        }
        
        return status == errSecSuccess ? (dataTypeRef as? Data) : nil
    }
    
    /// Delete data from the keychain
    @discardableResult
    static func basiOS_delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            os_log("Failed to delete keychain item for key %{public}@. Status: %d", log: OSLog.keychain, type: .error, key, status)
        }
        
        // Return true if the item was successfully deleted or not found
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// Define a custom OSLog category for keychain-related logs
extension OSLog {
    static let keychain = OSLog(subsystem: "com.basiOS.keychain", category: "Keychain")
}
