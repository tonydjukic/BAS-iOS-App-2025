//
//  basiOS_Config.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-11.
//

import Foundation

struct Config {
    // Base API URL depending on the build configuration
    static var apiBaseURL: String {
        #if DEBUG
        return "https://bramptonsoccer.flywheelstaging.com/wp-json/baslms/v1"
        #else
        return "https://bramptonsoccer.com/wp-json/baslms/v1"
        #endif
    }
}
