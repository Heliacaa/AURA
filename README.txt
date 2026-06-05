AURA - iOS SOURCE CODE AND RUNNING INSTRUCTIONS
===============================================

Course: SE 380 - Mobile Application Development
Institution: Izmir University of Economics
Project version: 1.0.0+1
Flutter version used: 3.41.5 stable
Dart version used: 3.11.3
YouTube demonstration URL: [ADD THE FINAL YOUTUBE URL BEFORE SUBMISSION]


1. WHAT THIS PROJECT IS
-----------------------

AURA is an iOS-only Flutter life-coaching app. It combines daily wellness
tracking, AI chat, AI meal-image analysis, quests, XP/levels, achievements,
friends, leaderboards, community challenges, and an activity feed.

The Firebase integration uses Authentication and Cloud Firestore and is
designed for the Spark plan. Social milestones and challenge progress are
written by the Flutter client under restrictive Firestore rules.

Meal photographs are used in memory only during Gemini analysis. Saved scan
history contains the food name, date, calories, macros, and AI advice without
retaining the photograph.


2. REQUIRED SOFTWARE
--------------------

- macOS with Xcode
- Flutter 3.41.5 stable, including Dart 3.11.3
- CocoaPods
- An iOS 14.0 or newer device or simulator
- A Flutter-capable editor such as VS Code
- Internet access for Firebase, Gemini, and Google Sign-In
- A Gemini API key from Google AI Studio

Only needed for Firestore deployment and rule tests:

- Firebase CLI
- Node.js and npm
- Java for the Firestore emulator


3. OPEN AND INSTALL
-------------------

1. Open the folder containing pubspec.yaml, lib, test, and this README.txt.
2. Open a terminal in that folder.
3. Run:

    flutter --version
    flutter doctor
    flutter pub get
    cd ios
    pod install
    cd ..

The first command should report Flutter 3.41.5 stable and Dart 3.11.3. A newer
compatible Flutter version may work, but 3.41.5 is the tested version.


4. CREATE THE REQUIRED .env FILE
--------------------------------

The .env file contains the Gemini API key and is intentionally excluded from
Git/source submission.

1. Duplicate .env.example and name the duplicate .env.
2. Replace:

    GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE

   with a valid key:

    GEMINI_API_KEY=your_real_key_here

3. Do not commit or publicly share this file.

Without a valid key, account and data features can still work when Firebase is
configured, but AI chat and meal analysis will not work.


5. CONFIRM FIREBASE CONFIGURATION
---------------------------------

AURA uses Firebase Authentication and Cloud Firestore.

The repository contains the class project's iOS Firebase configuration. In the
Firebase console, enable:

- Authentication: Email/Password and Google providers
- Cloud Firestore

Deploy the included Firestore rules and indexes before evaluating social write
behavior. The evaluator must have permission to use the selected Firebase
project. Never replace configuration files with unrelated private credentials
in a public submission.


6. RUN THE APPLICATION
----------------------

1. Connect a physical iPhone or start an iOS simulator.
2. Check that Flutter can see it:

    flutter devices

3. Run the app:

    flutter run

4. Create an account or use Google Sign-In.
5. Grant camera, photo-library, motion/activity, notification, and HealthKit
   permissions when requested.

A physical iPhone is recommended for complete camera, motion, HealthKit, and
local-notification testing.


7. HOW TO USE THE APP
---------------------

ACCOUNT AND PROFILE

1. Register or sign in.
2. Open Edit Profile to set name, private body details, social energy, goals,
   Weekly League visibility, milestone sharing, and local reminder preferences.
3. Height and weight stay in the user's private profile.

HOME TAB

1. Review the Daily Score, steps, water, sleep, meals, and streak.
2. Complete and claim daily or weekly quests.
3. Use the step controls or HealthKit synchronization and add water.
4. Step and water changes update joined challenge contributions.

ASSISTANT TAB

1. Ask the Gemini-powered coach a question.
2. The coach uses recent chat, today's wellness data, remembered facts, and
   active community challenges as context.
3. AI responses may be incorrect and are not medical advice.

SCAN TAB

1. Take a food photograph or choose one from the photo library.
2. Wait for Gemini Vision to estimate the food name, calories, protein,
   carbohydrates, fat, and advice.
3. Save the meal to add its nutrition data to today's totals and earn XP.
4. Open a previous scan to review its date, nutrition estimate, and advice.
5. The selected photograph is not uploaded or retained after analysis.

CHARACTER TAB

1. Review the current level, class, XP progress, stats, and achievements.
2. Milestone sharing creates deterministic friend-feed events for streak,
   level-up, and achievement milestones when enabled.

SOCIAL TAB

1. Activity Feed: review global and current-friend activity cards and like
   visible activities.
2. Challenges: join or leave admin-created community step/water challenges.
   Displayed totals are calculated from non-decreasing daily contributions.
3. Ranking: use Weekly League or friend rankings.
4. Friends: search by exact email, send or manage requests, open profiles, or
   remove a friend.
5. Removing a friend immediately removes access to earlier friend-only events.


8. QUALITY CHECKS
-----------------

From the repository root, run:

    flutter analyze
    flutter test
    npm run test:rules

Verified on June 4, 2026:

- flutter analyze: no issues found
- flutter test: all 121 tests passed
- npm run test:rules: all 9 Firestore rule tests passed


9. OPTIONAL FIREBASE DEPLOYMENT
-------------------------------

Deploy only the Firestore rules and indexes:

    firebase deploy --only firestore:rules,firestore:indexes

The app has no separately deployed application backend. Community challenge
definitions are created and managed manually in Firestore.

Water and daily-goal reminders are scheduled locally by the iOS app. They do
not use remote push delivery. Enable them in Edit Profile and grant iOS
notification permission when asked.


10. IMPORTANT SOURCE LOCATIONS
------------------------------

- lib/main.dart: application startup
- lib/core/: routing, theme, utilities, and Gemini configuration
- lib/features/auth/: login and registration
- lib/features/home/: dashboard, health summary, and quests
- lib/features/chat/: AI coach
- lib/features/scan/: in-memory AI food scanning and scan history
- lib/features/character/: XP, stats, classes, and achievements
- lib/features/social/: feed, challenges, rankings, and friends
- lib/features/profile/: private, editable, and public profiles
- lib/services/: Firestore, health, notification, social, and AI memory
- lib/shared/: shared data models and widgets
- firestore.rules: Firestore access-control rules
- firestore.indexes.json: required composite indexes
- test/: Flutter automated tests
- test-rules/: Firestore emulator rule tests
- samplereport.tex: final report source
- samplereport.pdf: compiled final report


11. DATA AND SECURITY NOTES
---------------------------

- Legacy meal imageUrl fields are ignored; no migration is required.
- Legacy challenge currentAmount fields are ignored.
- Social milestone document IDs are deterministic and events are immutable.
- Friend-only event reads require a currently accepted friendship.
- Likes live under the current user's document and are loaded as one stream.
- Challenge contributions belong to their author, cannot decrease, and cannot
  exceed the matching daily log.
- Leaving a challenge keeps past contributions but prevents new ones.


12. TROUBLESHOOTING
-------------------

AI features fail:
- Confirm that .env exists and GEMINI_API_KEY contains a valid key.
- Run flutter pub get and restart the app.

Firebase initialization or permission errors:
- Confirm the iOS Firebase configuration is valid.
- Confirm Authentication and Firestore are enabled.
- Deploy firestore.rules and firestore.indexes.json to the intended project.

Camera, steps, HealthKit, or notifications do not work:
- Use a physical iPhone when possible.
- Grant the requested permissions in iOS Settings.
- Confirm a local reminder toggle is enabled under Edit Profile.

Social sections are empty:
- Sign in, refresh, and confirm Firestore is connected.
- Challenges require admin-created Firestore definitions.
- Feed events appear after real streak, level-up, or achievement milestones.
- Add another account by exact email to test friends and rankings.


13. KNOWN LIMITATIONS
---------------------

- Full functionality requires an accessible Firebase project and Gemini key.
- Remote push delivery is intentionally disabled; reminders are local to iOS.
- Community challenge definitions are managed manually in Firestore.
- English and Turkish localization resources exist, but some interface text
  remains hard-coded in Turkish.
- AI meal estimates and coaching responses can be inaccurate and are not
  medical advice.


14. EXTERNAL HELP AND ACADEMIC-INTEGRITY DISCLOSURE
---------------------------------------------------

Team contributions:

- Beyazit: app foundation, Firebase/auth/data integration, home and health
  tracking, quests and progression, character/profile flows, friends/public
  profiles, privacy rules, weekly league integration, notifications, and tests.
- Ediz Arkin Kobak: Gemini chat and memory flow, AI meal vision and scan-history
  improvements, social challenges/activity feed, leaderboard presentation
  widgets, environment configuration, and related UI improvements.

External help/resources:

- Previous projects created by the team were used as general design and
  implementation references. Add their exact titles/repository URLs to the
  final disclosure if they were materially consulted.
- AI development tools, especially OpenAI Codex, were used for brainstorming,
  debugging, code review, test/documentation assistance, and refinement. The
  team reviewed and remains responsible for all final code and claims.
- Official Flutter, Dart, Firebase, Google Sign-In, Gemini, Apple Health, and
  package documentation was consulted.
- Third-party packages declared in pubspec.yaml were installed through their
  normal package managers.
- Standard Flutter platform scaffold and generated configuration files were
  used.

This was not a joint project with another class.
