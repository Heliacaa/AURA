# AURA

AURA is a Flutter life-coaching application that combines wellness tracking,
AI-assisted guidance, meal analysis, RPG-style progression, and social
accountability.

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
- Daily and weekly quests with claimable XP, stats, levels, classes, and
  achievements
- Gemini-powered personal coach with chat history and remembered user context
- Gemini Vision meal scanning with calorie/macronutrient estimates, advice,
  image storage, and scan history
- Friends, requests, public profiles, activity feed, likes, community
  challenges, friend rankings, and an opt-in weekly league
- HealthKit sleep/step synchronization on iOS and live pedometer step tracking
- Firebase Authentication, Firestore, Storage, Cloud Functions, security rules,
  and offline Firestore persistence

## Quick Start

The most reliable demonstration target is a physical iOS or Android device.
Some health, camera, and notification features are limited on desktop or web.

1. Install Flutter `3.41.5` stable and confirm the installation:

   ```sh
   flutter --version
   flutter doctor
   ```

2. Open this repository folder as a project in Android Studio, VS Code, or
   another Flutter-capable editor.

3. Install Flutter dependencies:

   ```sh
   flutter pub get
   ```

4. Create the local Gemini configuration:

   ```sh
   cp .env.example .env
   ```

   Replace `YOUR_GEMINI_API_KEY_HERE` in `.env` with a Google AI Studio Gemini
   API key. Never commit the `.env` file.

5. Confirm Firebase configuration:

   - The repository contains the class project's iOS and web Firebase options.
   - Android and macOS values in `lib/firebase_options.dart` are placeholders.
   - To connect another Firebase project or run Android/macOS, install the
     FlutterFire CLI and run `flutterfire configure`, then enable Email/Password
     and Google authentication, Firestore, and Storage in Firebase.

6. Connect a device or start an emulator, then run:

   ```sh
   flutter devices
   flutter run
   ```

7. Create an account or sign in. Grant camera, motion/activity, notification,
   and Apple Health permissions when requested.

For a step-by-step guide intended for a first-time evaluator, use
`README.txt`.

## Verification

Run the following commands from the repository root:

```sh
flutter analyze
flutter test
```

Verified on June 4, 2026:

- `flutter analyze`: no issues found
- `flutter test`: all 103 tests passed

## Optional Firebase Deployment

Deploy Firestore rules:

```sh
firebase deploy --only firestore:rules
```

Install and deploy Cloud Functions:

```sh
cd functions
npm install
firebase deploy --only functions
```

The Cloud Functions project targets Node.js 18. Deployment requires access to
the intended Firebase project.

## Source Layout

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App startup, Firebase, environment, notifications, and localization |
| `lib/core/` | Router, theme, date utilities, haptics, and Gemini configuration |
| `lib/features/` | Auth, home, chat, scan, character, social, and profile features |
| `lib/services/` | Firebase, health, notifications, storage, social, memory, and auth services |
| `lib/shared/` | Shared models and reusable widgets |
| `lib/l10n/` | English and Turkish localization resources |
| `functions/` | Firebase Cloud Functions |
| `firestore.rules` | Firestore access-control rules |
| `test/` | Unit, service, and widget tests |
| `samplereport.tex` | Final project report source |

## External Services and Configuration

- Firebase Authentication, Cloud Firestore, Firebase Storage, Firebase
  Messaging, and Cloud Functions
- Google Sign-In
- Google Gemini through `google_generative_ai`
- Apple HealthKit, device motion/activity data, camera, and photo library
- Pub.dev packages declared in `pubspec.yaml`

AI-generated health and nutrition responses are estimates and are not medical
advice.

## Known Limitations

- A valid Gemini API key and an accessible Firebase project are required for
  the complete experience.
- Android and macOS Firebase options must be generated before those platforms
  can use Firebase.
- The client initializes local notifications and the backend contains a
  scheduled Firebase Messaging function, but automatic client FCM-token
  registration is not currently wired end to end.
- The social challenge/activity collections use demo seed data and should be
  hardened before production use.
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
