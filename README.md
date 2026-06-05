# AURA

AURA is an iOS-only Flutter life-coaching application that combines wellness
tracking, AI-assisted guidance, meal analysis, RPG-style progression, and
social accountability. Its Firebase integration is designed to run on the
Spark plan with Authentication and Cloud Firestore.

## Submission Information

- Course: SE 380 - Mobile Application Development
- Institution: Izmir University of Economics
- Project version: `1.0.0+1`
- Flutter version used: `3.41.5` stable
- Dart version used: `3.11.3`
- YouTube demonstration URL: **[ADD THE FINAL YOUTUBE URL BEFORE SUBMISSION]**
- Full report source: `samplereport.tex`
- Generated report PDF: `samplereport.pdf`
- Required plain-text setup guide: `README.txt`

## Main Features

- Email/password registration, login, Google Sign-In, and protected routes
- Personal profile, editable goals, private body data, and public/friend views
- Daily dashboard for steps, water, sleep, meals, streaks, and daily score
- Daily and weekly quests with XP, stats, levels, classes, and achievements
- Gemini-powered personal coach with chat history and remembered user context
- Gemini Vision meal scanning with calorie/macronutrient estimates and advice
- Friends, requests, public profiles, activity feed, per-user likes, community
  challenges, rankings, unread counters, and an opt-in weekly league
- HealthKit sleep/step synchronization and device-scheduled local reminders
- Firebase Authentication, Cloud Firestore, security rules, indexes, and
  offline Firestore persistence

Meal photographs are used in memory only while Gemini analyzes them. Saved meal
history contains the food name, date, calories, macros, and AI advice, but no
photograph.

Social milestone events and challenge contributions are written by the Flutter
client under restrictive Firestore rules. Community challenge definitions
remain admin-managed in Firestore.

## iOS Quick Start

The supported demonstration target is an iOS 14.0 or newer device or simulator.
A physical iPhone is recommended for camera, motion, HealthKit, and notification
testing.

1. Install Flutter `3.41.5` stable, Xcode, and CocoaPods.
2. Open the repository in a Flutter-capable editor.
3. Install dependencies:

   ```sh
   flutter pub get
   cd ios
   pod install
   cd ..
   ```

4. Create the local Gemini configuration:

   ```sh
   cp .env.example .env
   ```

   Replace `YOUR_GEMINI_API_KEY_HERE` in `.env` with a Google AI Studio Gemini
   API key. Never commit the `.env` file.

5. Confirm that the selected Firebase project has Email/Password and Google
   authentication enabled, plus a Cloud Firestore database.
6. Connect an iPhone or start an iOS simulator, then run:

   ```sh
   flutter devices
   flutter run
   ```

7. Grant camera, photo-library, motion/activity, notification, and HealthKit
   permissions when requested.

For a step-by-step evaluator guide, use `README.txt`.

## Verification

Run from the repository root:

```sh
flutter analyze
flutter test
npm run test:rules
```

Verified on June 4, 2026:

- `flutter analyze`: no issues found
- `flutter test`: all 121 tests passed
- `npm run test:rules`: all 9 Firestore rule tests passed

## Optional Firebase Deployment

The app has no separately deployed application backend. Deploy only the
Firestore rules and indexes:

```sh
firebase deploy --only firestore:rules,firestore:indexes
```

Water and daily-goal reminders are scheduled locally by the iOS app. Social
updates use real-time Firestore streams and in-app counters.

## Source Layout

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App startup, Firebase, environment, notifications, and localization |
| `lib/core/` | Router, theme, date utilities, haptics, and Gemini configuration |
| `lib/features/` | Auth, home, chat, scan, character, social, and profile features |
| `lib/services/` | Firestore, health, notifications, social, memory, and auth services |
| `lib/shared/` | Shared models and reusable widgets |
| `lib/l10n/` | English and Turkish localization resources |
| `firestore.rules` | Firestore access-control rules |
| `firestore.indexes.json` | Required Firestore composite indexes |
| `test/` | Flutter unit, service, and widget tests |
| `test-rules/` | Firestore emulator rule tests |
| `samplereport.tex` | Final project report source |

## Data and Security Notes

- Existing meal documents with a legacy `imageUrl` field remain readable; the
  field is ignored and no migration is required.
- Existing challenge definitions with a legacy `currentAmount` field remain
  readable; displayed totals are derived from contribution documents.
- Milestone activity IDs are deterministic, and activity documents are
  immutable after creation.
- Friend-only activity access follows the current accepted friendship. Removing
  a friend removes access to earlier friend-only events.
- Likes live below the current user's document. Challenge contributions belong
  to their author, cannot decrease, and cannot exceed the matching daily log.

## External Services

- Firebase Authentication and Cloud Firestore
- Google Sign-In
- Google Gemini through `google_generative_ai`
- Apple HealthKit, device motion/activity data, camera, and photo library
- Pub.dev packages declared in `pubspec.yaml`

AI-generated health and nutrition responses are estimates and are not medical
advice.

## Known Limitations

- A valid Gemini API key and accessible Firebase project are required for the
  complete experience.
- Remote push delivery is intentionally disabled; reminders are local to iOS.
- Community challenge definitions are managed manually in Firestore.
- English and Turkish localization resources exist, but several screens still
  contain hard-coded Turkish text.
- Meal analysis is an AI estimate; users should verify nutritional information.

## Team and External Help Disclosure

- Beyazit: app foundation, Firebase/auth/data integration, home and health
  tracking, quests and progression, character/profile flows, friends/public
  profiles, privacy rules, weekly league integration, notifications, and tests.
- Ediz Arkin Kobak: Gemini chat and memory flow, AI meal vision and scan-history
  improvements, social challenges/activity feed, leaderboard presentation
  widgets, environment configuration, and related UI improvements.
- Previous projects created by the team were used as general design and
  implementation references. Their exact titles/repository URLs must be added
  to the final submission disclosure if they were materially consulted.
- AI development tools, especially OpenAI Codex, were used for brainstorming,
  debugging, code review, test/documentation assistance, and refinement. The
  team reviewed and remains responsible for all final code and claims.
- Flutter, Firebase, Gemini, package documentation, and generated platform
  scaffold files were used.
- This was not a joint project with another class.

Git history records the team's integration work, but it does not prove every AI
interaction. Relevant AI conversation exports can be provided separately if
the instructor requests them.
