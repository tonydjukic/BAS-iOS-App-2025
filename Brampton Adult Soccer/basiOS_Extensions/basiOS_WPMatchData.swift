//
//  basiOS_WPMatchData.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-05.
//

import Foundation

struct basiOS_WPMatchData {
    private static let basiOS_baseURL = Config.apiBaseURL // Use Config for API base URL
    
    static func basiOS_fetchMatchData(
        userID: Int,
        login: String,
        password: String,
        completion: @escaping (Result<basiOS_MatchDataResponse, Error>) -> Void
    ) {
        var components = URLComponents(string: "\(basiOS_baseURL)/user-sessions")!
        //components.queryItems = [URLQueryItem(name: "user_id", value: "\(userID)")]
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "BASiOS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let credentials = ["login": login, "password": password]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: credentials)
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
                completion(.failure(NSError(domain: "BASiOS", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "BASiOS", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if httpResponse.statusCode == 401 {
                completion(.failure(NSError(domain: "BASiOS", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])))
                return
            }
            
//            do {
//                let response = try JSONDecoder().decode(basiOS_MatchDataResponse.self, from: data)
//                completion(.success(response))
//            } catch {
//                completion(.failure(error))
//            }
            do {
                let response = try JSONDecoder().decode(basiOS_MatchDataResponse.self, from: data)
                var mutableResponse = response
                mutableResponse.preprocess() // Decode all HTML entities
                completion(.success(mutableResponse))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
