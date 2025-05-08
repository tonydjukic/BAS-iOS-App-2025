//
//  basiOS_WPAuth.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-04-30.
//

import Foundation
import os.log

struct basiOS_WPAuth {
    private static let basiOS_baseURL = "https://bramptonsoccer.com/wp-json/baslms/v1"
    
    static func basiOS_authenticate(
        login: String,
        password: String,
        completion: @escaping (Result<basiOS_AuthResponse, Error>) -> Void
    ) {
        let endpoint = "\(basiOS_baseURL)/authenticate"
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "com.basiOS.auth", code: -1,
                                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        let credentials = ["login": login, "password": password]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: credentials)
            os_log("AUTH REQUEST: %{public}@", log: OSLog.auth, type: .info, String(data: request.httpBody!, encoding: .utf8) ?? "Invalid body")
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "com.basiOS.auth", code: -2,
                                             userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "com.basiOS.auth", code: -3,
                                             userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            os_log("RAW RESPONSE: %{public}@", log: OSLog.auth, type: .info, String(data: data, encoding: .utf8) ?? "Invalid data")
            
            do {
                let response = try JSONDecoder().decode(basiOS_AuthResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

// Define a custom OSLog category for auth-related logs
extension OSLog {
    static let auth = OSLog(subsystem: "com.basiOS.auth", category: "Authentication")
}

struct basiOS_AuthResponse: Codable {
    let success: Bool
    let data: basiOS_AuthData
}

struct basiOS_AuthData: Codable {
    let user: basiOS_User
    let sessionToken: String
    
    enum CodingKeys: String, CodingKey {
        case user
        case sessionToken = "session_token"
    }
}

struct basiOS_User: Codable {
    let id: Int
    let email: String
    let displayName: String
    let firstName: String?
    let lastName: String?
    let roles: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case roles
    }
}
