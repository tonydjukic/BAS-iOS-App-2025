//
//  basiOS_MatchDataModels.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-05.
//

import Foundation

struct basiOS_MatchDataResponse: Codable {
    let success: Bool
    let data: basiOS_MatchData
}

struct basiOS_MatchData: Codable {
    let active_sessions: String
    let team_data: [basiOS_TeamData]
    let api_version: String
}

struct basiOS_TeamData: Codable {
    let team_id: Int
    let team_name: String
    let is_team_suspended: Bool
    let matches: [basiOS_Match]
    var decoded_team_name: String {
        decodeHTMLEntities(team_name)
    }
}

struct basiOS_Match: Codable, Identifiable {
    let match_id: Int
    let match_date: String
    let match_time: String
    let venue: basiOS_Venue
    let home_team: basiOS_Team
    let away_team: basiOS_Team
    let user_attending: String
    let is_suspended: Bool
    var id: Int { match_id }
}

struct basiOS_Venue: Codable {
    let title: String
    let map_url: String?
}

struct basiOS_Team: Codable {
    let id: Int
    let name: String
    let jersey_color: String
    var decoded_name: String {
        decodeHTMLEntities(name)
    }
}
