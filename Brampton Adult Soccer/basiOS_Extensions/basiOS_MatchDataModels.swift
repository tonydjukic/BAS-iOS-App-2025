//
//  basiOS_MatchDataModels.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-05.
//

import Foundation

struct basiOS_MatchDataResponse: Codable {
    let success: Bool
    var data: basiOS_MatchData
    
    mutating func preprocess() {
        data.preprocess()
    }
}

struct basiOS_MatchData: Codable {
    let active_sessions: String
    var team_data: [basiOS_TeamData]
    let api_version: String

    mutating func preprocess() {
        team_data = team_data.map { team in
            var updatedTeam = team
            updatedTeam.preprocess()
            return updatedTeam
        }
    }
}

struct basiOS_TeamData: Codable {
    let team_id: Int
    var team_name: String
    let is_team_suspended: Bool
    var matches: [basiOS_Match]

    mutating func preprocess() {
        team_name = decodeHTMLEntities(team_name)
        matches = matches.map { match in
            var updatedMatch = match
            updatedMatch.preprocess()
            return updatedMatch
        }
    }
}

struct basiOS_Match: Codable, Identifiable, Equatable {
    let match_id: Int
    var match_date: String
    var match_time: String
    var venue: basiOS_Venue
    var home_team: basiOS_Team
    var away_team: basiOS_Team
    let user_attending: String
    let is_suspended: Bool

    var id: Int { match_id }
    // Equatable conformance
    static func == (lhs: basiOS_Match, rhs: basiOS_Match) -> Bool {
        return lhs.match_id == rhs.match_id
    }

    mutating func preprocess() {
        home_team.preprocess()
        away_team.preprocess()
        venue.preprocess()
    }
}

struct basiOS_Venue: Codable {
    var title: String
    var map_url: String?

    mutating func preprocess() {
        title = decodeHTMLEntities(title)
    }
}

struct basiOS_Team: Codable {
    let id: Int
    var name: String
    let jersey_color: String

    mutating func preprocess() {
        name = decodeHTMLEntities(name)
    }
}
