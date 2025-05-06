//
//  Brampton_Adult_SoccerApp.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-04-30.
//

import SwiftUI

@main
struct Brampton_Adult_SoccerApp: App {
    @AppStorage("basiOS_isAuthenticated") var basiOS_isAuthenticated = false
    
    var body: some Scene {
        WindowGroup {
            if basiOS_isAuthenticated {
                basiOS_HomeView(basiOS_isAuthenticated: $basiOS_isAuthenticated)
            } else {
                basiOS_LoginView(basiOS_isAuthenticated: $basiOS_isAuthenticated)
            }
        }
    }
}
