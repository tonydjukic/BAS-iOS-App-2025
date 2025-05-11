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
            kSecAttrAccount as String: key
        ]

        // Check if the item already exists
        var dataTypeRef: AnyObject?
        let matchStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if matchStatus == errSecSuccess {
            // Update the item if it exists
            let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
            if updateStatus != errSecSuccess {
                os_log("Error: Failed to update keychain item. Status: %d", log: OSLog.keychain, type: .error, updateStatus)
            }
            return updateStatus == errSecSuccess
        } else if matchStatus == errSecItemNotFound {
            // Add the item if it does not exist
            var newQuery = query
            newQuery[kSecValueData as String] = data
            newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock // Accessibility
            let addStatus = SecItemAdd(newQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                os_log("Error: Failed to add keychain item. Status: %d", log: OSLog.keychain, type: .error, addStatus)
            }
            return addStatus == errSecSuccess
        } else {
            // Log unexpected errors
            os_log("Error: Unexpected error during keychain operation. Status: %d", log: OSLog.keychain, type: .error, matchStatus)
            return false
        }
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
            os_log("Error: Failed to load keychain item. Status: %d", log: OSLog.keychain, type: .error, status)
            return nil
        }

        return dataTypeRef as? Data
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
            os_log("Error: Failed to delete keychain item. Status: %d", log: OSLog.keychain, type: .error, status)
        }

        // Return true if the item was successfully deleted or not found
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// Define a custom OSLog category for keychain-related logs
extension OSLog {
    static let keychain = OSLog(subsystem: "com.basiOS.keychain", category: "Keychain")
}
