AURA - SOURCE CODE AND RUNNING INSTRUCTIONS
===========================================

Course: SE 380 - Mobile Application Development
Institution: Izmir University of Economics
Project version: 1.0.0+1
Flutter version used: 3.41.5 stable
Dart version used: 3.11.3
YouTube demonstration URL: [ADD THE FINAL YOUTUBE URL BEFORE SUBMISSION]


1. WHAT THIS PROJECT IS
-----------------------

AURA is a Flutter mobile life-coaching app. It combines daily wellness
tracking, AI chat, AI meal-image analysis, quests, XP/levels, achievements,
friends, leaderboards, community challenges, and an activity feed.

The recommended evaluation target is a physical iOS or Android device because
the camera, motion/activity, health, and notification features are not fully
available on every emulator, desktop platform, or web browser.


2. REQUIRED SOFTWARE
--------------------

Install these before opening the project:

- Flutter 3.41.5 stable, which includes Dart 3.11.3
- Android Studio or VS Code with Flutter/Dart support
- For iOS: macOS, Xcode, CocoaPods, and an iOS 14.0 or newer device/simulator
- For Android: Android Studio and an Android SDK/device or emulator
- Internet access for Firebase, Gemini, and Google Sign-In
- A Gemini API key from Google AI Studio for AI chat and meal scanning

Only needed when deploying backend files:

- Firebase CLI
- Node.js 18 and npm


3. OPEN THE SOURCES AS A PROJECT
--------------------------------

1. Extract the submitted source folder if it is compressed.
2. Open Android Studio or VS Code.
3. Choose "Open Folder" or "Open Existing Project".
4. Select the folder containing pubspec.yaml, lib, test, and this README.txt.
5. Open a terminal in that same folder.


4. INSTALL PROJECT DEPENDENCIES
-------------------------------

From the repository root, run:

    flutter --version
    flutter doctor
    flutter pub get

The first command should report Flutter 3.41.5 stable and Dart 3.11.3. A newer
compatible Flutter version may work, but 3.41.5 is the version used and tested
by the team.


5. CREATE THE REQUIRED .env FILE
--------------------------------

The .env file contains the Gemini API key and is intentionally excluded from
Git/source submission.

1. Duplicate .env.example and name the duplicate .env.
2. Open .env in a plain-text editor.
3. Replace the placeholder:

    GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE

   with a valid key:

    GEMINI_API_KEY=your_real_key_here

4. Do not commit or publicly share this file.

Without a valid key, account/data features can still work when Firebase is
configured, but AI chat and meal analysis will not work.


6. CONFIRM FIREBASE CONFIGURATION
---------------------------------

AURA uses Firebase Authentication, Firestore, Storage, Messaging, and Cloud
Functions.

- The submitted repository contains the class project's iOS and web Firebase
  options.
- Android and macOS entries in lib/firebase_options.dart are placeholders.
- If the included Firebase project is unavailable, or if Android/macOS must be
  used, connect a Firebase project with FlutterFire:

    dart pub global activate flutterfire_cli
    flutterfire configure

In the Firebase console, enable:

- Authentication: Email/Password and Google providers
- Cloud Firestore
- Firebase Storage
- Firebase Messaging/Cloud Functions if notifications are evaluated

The evaluator must have permission to use the selected Firebase project. Never
replace configuration files with unrelated private credentials in a public
submission.


7. RUN THE APPLICATION
----------------------

1. Connect a physical device or start an emulator/simulator.
2. Check that Flutter can see it:

    flutter devices

3. Run the app:

    flutter run

4. Create an account with name, email, and a password of at least six
   characters, or use Google Sign-In.
5. Grant camera, photo, motion/activity, notification, and Apple Health
   permissions when requested. Denying them limits the related features but
   should not prevent basic navigation.

For iOS dependency problems, run this from the repository root and try again:

    cd ios
    pod install
    cd ..
    flutter run


8. HOW TO USE THE APP
---------------------

ACCOUNT AND PROFILE

1. Register or sign in.
2. On the Home screen, tap the name/avatar area to open the account menu.
3. Open "Edit Profile" to set name, age, optional height/weight, social energy,
   step goal, calorie goal, water goal, and Weekly League visibility.
4. Height and weight stay in the user's private profile. Public and friend
   profile views expose only their intended fields.

HOME TAB

1. Review the Daily Score, which summarizes steps, meals, water, and streak.
2. Complete daily/weekly quest requirements and press the claim button when a
   reward becomes available.
3. Use the step controls/live device tracking, add water, and log sleep.
4. Review today's meal macros and active community challenges.
5. Pull down to refresh and resynchronize today's data.

ASSISTANT TAB

1. Enter a question or goal and press Send.
2. The Gemini-powered coach uses recent chat, today's wellness data, selected
   remembered facts, and active community challenges as context.
3. Each successful chat interaction awards XP/intelligence progress.
4. Use the delete button to clear the stored chat history.
5. AI responses may be incorrect and are not medical advice.

SCAN TAB

1. Tap the image area or camera option to take a food photograph, or choose an
   image from the gallery.
2. Wait for Gemini Vision to estimate the food name, calories, protein,
   carbohydrates, fat, and personalized advice.
3. Review the estimate before saving it.
4. Save the meal to add it to today's totals and earn XP.
5. Open a previous scan to review its image, date, nutrition estimate, and
   advice.

CHARACTER TAB

1. Review current level, class, XP progress, and the Strength, Intelligence,
   Charisma, and Vitality stats.
2. Review recent XP/stat gains.
3. Review unlocked and locked achievements.
4. Earn progress by chatting, saving meals, and claiming quests.

SOCIAL TAB

1. Activity Feed: review activity cards, open profiles, and like activities.
2. Challenges: join or leave community step/water challenges. Joined challenge
   progress increases when related actions are recorded.
3. Ranking: use Weekly League for opt-in weekly XP rankings or Friends for
   friend rankings. Tap a user to open the public profile.
4. Friends: search using an exact email address, send a request, accept/reject
   requests, open profiles, or remove a friend.


9. RUN QUALITY CHECKS
---------------------

From the repository root, run:

    flutter analyze
    flutter test

Verified on June 4, 2026:

- flutter analyze: no issues found
- flutter test: all 103 tests passed

The test suite covers models, date utilities, health-data calculations, quest
evaluation and claiming, achievements, Firestore behavior, friendship behavior,
leaderboard privacy/opt-in behavior, and widget smoke tests.


10. OPTIONAL FIREBASE BACKEND DEPLOYMENT
----------------------------------------

These steps are not required just to read the sources. They require Firebase
project access.

Deploy Firestore rules:

    firebase deploy --only firestore:rules

Install and deploy Cloud Functions:

    cd functions
    npm install
    firebase deploy --only functions

Cloud Functions use Node.js 18. They include daily-log reset/support logic and
a scheduled coaching-notification function.


11. IMPORTANT SOURCE LOCATIONS
------------------------------

- lib/main.dart: application startup
- lib/core/: routing, theme, utilities, and Gemini configuration
- lib/features/auth/: login and registration
- lib/features/home/: dashboard, health summary, and quests
- lib/features/chat/: AI coach
- lib/features/scan/: AI food scanning and scan history
- lib/features/character/: XP, stats, classes, and achievements
- lib/features/social/: feed, challenges, rankings, and friends
- lib/features/profile/: private, editable, and public profiles
- lib/services/: Firebase, health, notification, social, storage, and AI memory
- lib/shared/: shared data models and widgets
- functions/: Firebase Cloud Functions
- firestore.rules: Firestore access-control rules
- test/: automated tests
- samplereport.tex: final report source
- samplereport.pdf: compiled final report


12. TROUBLESHOOTING
-------------------

"API key not configured" or AI features fail:
- Confirm that .env exists in the repository root.
- Confirm that GEMINI_API_KEY contains a valid key.
- Run flutter pub get and restart the app.

Firebase initialization or permission errors:
- Confirm the selected platform has valid Firebase options.
- Confirm Authentication, Firestore, and Storage are enabled.
- Confirm firestore.rules is deployed to the intended Firebase project.

Camera/gallery/steps/health do not work:
- Use a supported physical mobile device when possible.
- Grant the requested operating-system permissions.
- Apple Health step/sleep import is iOS-specific; Android uses live pedometer
  data rather than Apple HealthKit.

Social sections are empty:
- Sign in, refresh, and confirm Firestore is connected.
- Challenges/activity feed may require demo seed data or existing documents.
- Add another account by exact email to test friend requests/rankings.

Notifications do not arrive:
- Local notification initialization and a scheduled backend notification
  function exist, but automatic client FCM-token registration is not currently
  complete. This is a documented project limitation.


13. EXTERNAL HELP AND ACADEMIC-INTEGRITY DISCLOSURE
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
- Third-party packages declared in pubspec.yaml and functions/package.json were
  installed through their normal package managers.
- Standard Flutter platform scaffold/generated files and FlutterFire-generated
  configuration patterns were used.
- To the team's knowledge, no undeclared downloaded source module or script was
  submitted as original team work.

This was not a joint project with another class. The work was prepared for
SE 380 - Mobile Application Development.

Git history records the team's commits and integration work, but cannot prove
every AI interaction. If proof of AI assistance is requested, relevant Codex
conversation exports can be attached separately. The disclosure above remains
the team's explicit declaration of that assistance.


14. KNOWN LIMITATIONS
---------------------

- Full functionality requires an accessible Firebase project and Gemini key.
- Android and macOS Firebase options are placeholders until configured.
- Notification delivery is not wired end to end because client FCM-token
  registration is incomplete.
- Social challenge/activity documents use demo-oriented data and permissions
  that should be hardened for production.
- English/Turkish localization resources exist, but some interface text remains
  hard-coded in Turkish.
- AI meal estimates and coaching responses can be inaccurate and are not
  medical advice.
