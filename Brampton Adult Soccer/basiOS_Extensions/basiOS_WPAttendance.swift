//
//  basiOS_WPAttendance.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-05.
//

import Foundation

struct basiOS_WPAttendance {
    private static let basiOS_baseURL = Config.apiBaseURL

    static func basiOS_setAttendance(
        login: String,
        password: String,
        teamID: Int,
        matchID: Int,
        status: String?, // "yes", "no", or nil = clear
        completion: @escaping (Result<basiOS_AttendanceResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(basiOS_baseURL)/ios_attendance") else {
            completion(.failure(NSError(domain: "BASiOS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        var body: [String: Any] = [
            "login": login,
            "password": password,
            "team_id": teamID,
            "match_id": matchID
        ]
        if let status = status {
            body["status"] = status
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
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

            do {
                let response = try JSONDecoder().decode(basiOS_AttendanceResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct basiOS_AttendanceResponse: Codable {
    let success: Bool
    let data: basiOS_AttendanceData
}

struct basiOS_AttendanceData: Codable {
    let team_id: Int
    let match_id: Int
    let status: String
}
