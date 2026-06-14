AURA - SOURCE CODE AND RUNNING INSTRUCTIONS
=============================================

Course: SE 380 - Mobile Application Development
Institution: Izmir University of Economics
Project version: 1.0.0+1
Flutter version used: 3.41.5 stable
Dart version used: 3.11.3
YouTube demonstration URL: https://youtu.be/8XAVZEF9t2w


1. WHAT THIS PROJECT IS
-----------------------

AURA is an iOS-only Flutter life-coaching app. It combines daily wellness
tracking, AI chat, AI meal-image analysis, quests, XP/levels, achievements,
friends, leaderboards, community challenges, and an activity feed.

The Firebase integration uses Authentication and Cloud Firestore.


2. REQUIRED SOFTWARE
--------------------

- macOS with Xcode
- Flutter 3.41.5 stable, including Dart 3.11.3
- CocoaPods
- An iOS 14.0 or newer device or simulator
- A Flutter-capable editor such as VS Code
- Internet access for Firebase, Gemini, and Google Sign-In
- A Gemini API key from Google AI Studio


3. STEP-BY-STEP SETUP AND RUN
------------------------------

Step 1: Verify Flutter installation

    flutter --version
    flutter doctor

    The output should report Flutter 3.41.5 stable and Dart 3.11.3.

Step 2: Open the project folder

    Open the folder containing pubspec.yaml, lib, test, and this README.txt
    in your editor.

Step 3: Install dependencies

    flutter pub get
    cd ios
    pod install
    cd ..

Step 4: Create the .env file

    Copy .env.example to .env and replace the placeholder with a valid key:

        GEMINI_API_KEY=your_real_key_here

    Without a valid key, AI chat and meal analysis will not work.

Step 5: Confirm Firebase configuration

    The repository contains the iOS Firebase configuration. In the Firebase
    console, enable:

    - Authentication: Email/Password and Google providers
    - Cloud Firestore

Step 6: Run the application

    Connect a physical iPhone or start an iOS simulator, then run:

        flutter devices
        flutter run

    Create an account or use Google Sign-In. Grant camera, photo-library,
    motion/activity, notification, and HealthKit permissions when requested.

Step 7: Verify code quality

    flutter analyze
    flutter test
