# BAS-iOS-App-2025
This is the official Brampton Adult Soccer iOS app that integrates and communicates with BramptonSoccer.com using the BAS LMS plugin.


## CHANGELOG

= 0.8.0 =
* FIX: In Team History, if a user has always been on the same team, there wasn't an unique ID for the team, so the Team History would iterate the correct number of teams but display the same data for the session.  This has been fixed by enumerating the array and working through the iterations that way.
* CHANGE: Resulting from an alternative method of obtaining a user ID, rather than using a parameter appended to the API calls, we are using the authenticated user's ID, we no longer need to include the `user_id` on our API calls.

= 0.7.0 =
* NEW: Preparing a new version for submission to the AppStore Connect review process after fixing the HTML Entities encoding/decoding issue and cleaning up a few details.

= 0.6.2 =
* NEW: Adding HTML entity decoding into the application so that things like apostrophes and ampersands are displayed properly.

= 0.6.1 =
* NEW: Adding Password Reset functionality on the LoginView screen in basiOS_LoginView.swift

= 0.6 =
* NEW: Making use of the `is_suspended` data we pass along from the WP `user_sessions` API to flag matches where a user is suspended.
* NEW: Resubmitting the app to the AppStore Connect platform.

= 0.4 =
* NEW: Added app icons for final build and release of first public version.
* FIX: basiOS_KeychainHelper.swift was unable to properly clear out user data when an individual would swith between accounts.

= 0.3 =
* NEW: Building out the full Player Profile view and including demographic data for the user: Photo (pending/approved) and a placeholder, name, DOB, Age, Phone, Alt. Phone, Email, Address, Team History with links to team pages on site.
* CHANGE: Cleaning up codebase to reduce individual file sizes and better organize functionality.
* UPCOMING: Ensure there is no duplication of duties or functions across files (see Toolbar)
* UPCOMING: The notification 'Bell' icon is temporarily hidden, we need to reactivate it and give it a purpose.

= 0.2 =
* NEW: Setting up a login screen when a user first launches the app, it retains the users credentials for WP because we'll repeatedly need them to fire to retrieve data that should ultimately be private.
* NEW: Establishing a Dashboard/Home View where we greet the user with a "Welcome Firstname Lastname" message and then we display their upcoming matches.
* NEW: Clicking on one of the nicely styled boxes for each upcoming match opens a slide up 'Sheet' that gives further match data, like a link to Google Maps for the venue, conversion of the date from `YYYY-MM-DD` to `Day-of-Week, Month, DD, YYYY`
* NEW: Started building out the profile page by adding the users name, next step will be to add their user photo from their BAS online profile.

= 0.1 =
* NEW: Just figuring out the whole xCode/SwiftUI/iOS coding.