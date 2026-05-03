import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AURA'**
  String get appTitle;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @dailyScore.
  ///
  /// In en, this message translates to:
  /// **'Daily Score'**
  String get dailyScore;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'{count} Steps'**
  String steps(int count);

  /// No description provided for @stepGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! 🎉'**
  String get stepGoalReached;

  /// No description provided for @stepGoalAlmost.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get stepGoalAlmost;

  /// No description provided for @stepGoalGood.
  ///
  /// In en, this message translates to:
  /// **'Going well!'**
  String get stepGoalGood;

  /// No description provided for @stepGoalStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get moving! 💪'**
  String get stepGoalStart;

  /// No description provided for @socialEnergy.
  ///
  /// In en, this message translates to:
  /// **'Social Energy: {level}'**
  String socialEnergy(String level);

  /// No description provided for @energyHigh.
  ///
  /// In en, this message translates to:
  /// **'Your energy is great! Socialize!'**
  String get energyHigh;

  /// No description provided for @energyMedium.
  ///
  /// In en, this message translates to:
  /// **'A balanced day.'**
  String get energyMedium;

  /// No description provided for @energyLow.
  ///
  /// In en, this message translates to:
  /// **'You should rest a bit.'**
  String get energyLow;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} Day Streak'**
  String streakDays(int count);

  /// No description provided for @waterProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {goal} Glasses of Water'**
  String waterProgress(int current, int goal);

  /// No description provided for @waterGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! 🎉'**
  String get waterGoalReached;

  /// No description provided for @waterDrinkMore.
  ///
  /// In en, this message translates to:
  /// **'Drink more water!'**
  String get waterDrinkMore;

  /// No description provided for @updateSteps.
  ///
  /// In en, this message translates to:
  /// **'Update Steps'**
  String get updateSteps;

  /// No description provided for @stepCount.
  ///
  /// In en, this message translates to:
  /// **'Step count'**
  String get stepCount;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// No description provided for @weeklyTrends.
  ///
  /// In en, this message translates to:
  /// **'Weekly Trends'**
  String get weeklyTrends;

  /// No description provided for @dailyQuests.
  ///
  /// In en, this message translates to:
  /// **'Daily Quests'**
  String get dailyQuests;

  /// No description provided for @dailyQuestProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} rewards claimed'**
  String dailyQuestProgress(int completed, int total);

  /// No description provided for @dailyQuestClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get dailyQuestClaim;

  /// No description provided for @dailyQuestClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get dailyQuestClaimed;

  /// No description provided for @dailyQuestLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get dailyQuestLocked;

  /// No description provided for @dailyQuestRewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'Quest reward claimed!'**
  String get dailyQuestRewardClaimed;

  /// No description provided for @dailyQuestAlreadyClaimed.
  ///
  /// In en, this message translates to:
  /// **'This quest is already claimed.'**
  String get dailyQuestAlreadyClaimed;

  /// No description provided for @dailyQuestClaimFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not claim quest: {error}'**
  String dailyQuestClaimFailed(String error);

  /// No description provided for @sleepQuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep Log'**
  String get sleepQuestTitle;

  /// No description provided for @sleepQuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log last night\'s sleep'**
  String get sleepQuestSubtitle;

  /// No description provided for @mealQuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Log'**
  String get mealQuestTitle;

  /// No description provided for @mealQuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan and save at least 1 meal'**
  String get mealQuestSubtitle;

  /// No description provided for @waterQuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Water Goal'**
  String get waterQuestTitle;

  /// No description provided for @waterQuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your daily water goal'**
  String get waterQuestSubtitle;

  /// No description provided for @stepsQuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Step Goal'**
  String get stepsQuestTitle;

  /// No description provided for @stepsQuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your daily step goal'**
  String get stepsQuestSubtitle;

  /// No description provided for @sleepCard.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepCard;

  /// No description provided for @sleepHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h sleep'**
  String sleepHours(String hours);

  /// No description provided for @sleepQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get sleepQualityGood;

  /// No description provided for @sleepQualityFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get sleepQualityFair;

  /// No description provided for @sleepQualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get sleepQualityPoor;

  /// No description provided for @logSleep.
  ///
  /// In en, this message translates to:
  /// **'Log Sleep'**
  String get logSleep;

  /// No description provided for @sleepHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours slept'**
  String get sleepHoursLabel;

  /// No description provided for @sleepQuality.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality'**
  String get sleepQuality;

  /// No description provided for @macroSummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Nutrition'**
  String get macroSummary;

  /// No description provided for @caloriesOf.
  ///
  /// In en, this message translates to:
  /// **'{consumed} / {goal} kcal'**
  String caloriesOf(int consumed, int goal);

  /// No description provided for @proteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proteinLabel;

  /// No description provided for @carbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbsLabel;

  /// No description provided for @fatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fatLabel;

  /// No description provided for @aiVisionScan.
  ///
  /// In en, this message translates to:
  /// **'AI Vision Scan'**
  String get aiVisionScan;

  /// No description provided for @tapToTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to take a food photo'**
  String get tapToTakePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @analyzingFood.
  ///
  /// In en, this message translates to:
  /// **'Analyzing food...'**
  String get analyzingFood;

  /// No description provided for @scanResults.
  ///
  /// In en, this message translates to:
  /// **'Scan Results'**
  String get scanResults;

  /// No description provided for @detected.
  ///
  /// In en, this message translates to:
  /// **'Detected: {food}'**
  String detected(String food);

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories: {count} kcal'**
  String calories(int count);

  /// No description provided for @macros.
  ///
  /// In en, this message translates to:
  /// **'Protein: {protein}g | Carbs: {carbs}g | Fat: {fat}g'**
  String macros(String protein, String carbs, String fat);

  /// No description provided for @advice.
  ///
  /// In en, this message translates to:
  /// **'Advice: {text}'**
  String advice(String text);

  /// No description provided for @remainingBudget.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {calories} kcal'**
  String remainingBudget(int calories);

  /// No description provided for @overBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget by {calories} kcal!'**
  String overBudget(int calories);

  /// No description provided for @mealSaved.
  ///
  /// In en, this message translates to:
  /// **'Meal saved! 🎉'**
  String get mealSaved;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed: {error}'**
  String analysisFailed(String error);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @characterProgress.
  ///
  /// In en, this message translates to:
  /// **'Character Progress'**
  String get characterProgress;

  /// No description provided for @levelAndClass.
  ///
  /// In en, this message translates to:
  /// **'Level {level} — {className}'**
  String levelAndClass(int level, String className);

  /// No description provided for @attributes.
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get attributes;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get strength;

  /// No description provided for @intelligence.
  ///
  /// In en, this message translates to:
  /// **'Intelligence'**
  String get intelligence;

  /// No description provided for @charisma.
  ///
  /// In en, this message translates to:
  /// **'Charisma'**
  String get charisma;

  /// No description provided for @vitality.
  ///
  /// In en, this message translates to:
  /// **'Vitality'**
  String get vitality;

  /// No description provided for @recentGains.
  ///
  /// In en, this message translates to:
  /// **'Recent Gains'**
  String get recentGains;

  /// No description provided for @noGainsToday.
  ///
  /// In en, this message translates to:
  /// **'No gains today. Complete your goals!'**
  String get noGainsToday;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @noAchievements.
  ///
  /// In en, this message translates to:
  /// **'No achievements yet. Keep going!'**
  String get noAchievements;

  /// No description provided for @levelUp.
  ///
  /// In en, this message translates to:
  /// **'LEVEL UP!'**
  String get levelUp;

  /// No description provided for @levelUpMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You reached Level {level}!'**
  String levelUpMessage(int level);

  /// No description provided for @newClass.
  ///
  /// In en, this message translates to:
  /// **'New Class: {className}'**
  String newClass(String className);

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @chatAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get chatAssistant;

  /// No description provided for @chatOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chatOnline;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatHint;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Say hi to your AI life coach! 👋'**
  String get chatEmpty;

  /// No description provided for @apiKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'API key not configured. Add GEMINI_API_KEY to .env or run with --dart-define=GEMINI_API_KEY=YOUR_KEY'**
  String get apiKeyMissing;

  /// No description provided for @homePage.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homePage;

  /// No description provided for @assistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistant;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @character.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get character;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriend;

  /// No description provided for @searchByEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by email'**
  String get searchByEmail;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent!'**
  String get requestSent;

  /// No description provided for @friendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendRequests;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @noFriends.
  ///
  /// In en, this message translates to:
  /// **'No friends yet. Add some!'**
  String get noFriends;

  /// No description provided for @weeklyXp.
  ///
  /// In en, this message translates to:
  /// **'Weekly XP'**
  String get weeklyXp;

  /// No description provided for @weeklyLeague.
  ///
  /// In en, this message translates to:
  /// **'Weekly League'**
  String get weeklyLeague;

  /// No description provided for @friendsRanking.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsRanking;

  /// No description provided for @weeklyLeagueActive.
  ///
  /// In en, this message translates to:
  /// **'Weekly League active'**
  String get weeklyLeagueActive;

  /// No description provided for @weeklyLeagueInactive.
  ///
  /// In en, this message translates to:
  /// **'Weekly League off'**
  String get weeklyLeagueInactive;

  /// No description provided for @weeklyLeagueActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You are ranked with {xp} XP this week.'**
  String weeklyLeagueActiveSubtitle(int xp);

  /// No description provided for @weeklyLeagueInactiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join to appear in the weekly XP ranking.'**
  String get weeklyLeagueInactiveSubtitle;

  /// No description provided for @weeklyLeagueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one is in this week\'s league yet. You can be first.'**
  String get weeklyLeagueEmpty;

  /// No description provided for @weeklyLeagueEnabled.
  ///
  /// In en, this message translates to:
  /// **'Weekly League visibility enabled.'**
  String get weeklyLeagueEnabled;

  /// No description provided for @weeklyLeagueDisabled.
  ///
  /// In en, this message translates to:
  /// **'Weekly League visibility disabled.'**
  String get weeklyLeagueDisabled;

  /// No description provided for @weeklyLeagueUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update leaderboard: {error}'**
  String weeklyLeagueUpdateFailed(String error);

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String rank(int rank);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
