// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AURA';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get dailyScore => 'Daily Score';

  @override
  String steps(int count) {
    return '$count Steps';
  }

  @override
  String get stepGoalReached => 'Goal reached! 🎉';

  @override
  String get stepGoalAlmost => 'Almost there!';

  @override
  String get stepGoalGood => 'Going well!';

  @override
  String get stepGoalStart => 'Let\'s get moving! 💪';

  @override
  String socialEnergy(String level) {
    return 'Social Energy: $level';
  }

  @override
  String get energyHigh => 'Your energy is great! Socialize!';

  @override
  String get energyMedium => 'A balanced day.';

  @override
  String get energyLow => 'You should rest a bit.';

  @override
  String streakDays(int count) {
    return '$count Day Streak';
  }

  @override
  String waterProgress(int current, int goal) {
    return '$current / $goal Glasses of Water';
  }

  @override
  String get waterGoalReached => 'Goal reached! 🎉';

  @override
  String get waterDrinkMore => 'Drink more water!';

  @override
  String get updateSteps => 'Update Steps';

  @override
  String get stepCount => 'Step count';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get weeklyTrends => 'Weekly Trends';

  @override
  String get sleepCard => 'Sleep';

  @override
  String sleepHours(String hours) {
    return '${hours}h sleep';
  }

  @override
  String get sleepQualityGood => 'Good';

  @override
  String get sleepQualityFair => 'Fair';

  @override
  String get sleepQualityPoor => 'Poor';

  @override
  String get logSleep => 'Log Sleep';

  @override
  String get sleepHoursLabel => 'Hours slept';

  @override
  String get sleepQuality => 'Sleep Quality';

  @override
  String get macroSummary => 'Today\'s Nutrition';

  @override
  String caloriesOf(int consumed, int goal) {
    return '$consumed / $goal kcal';
  }

  @override
  String get proteinLabel => 'Protein';

  @override
  String get carbsLabel => 'Carbs';

  @override
  String get fatLabel => 'Fat';

  @override
  String get aiVisionScan => 'AI Vision Scan';

  @override
  String get tapToTakePhoto => 'Tap to take a food photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get analyzingFood => 'Analyzing food...';

  @override
  String get scanResults => 'Scan Results';

  @override
  String detected(String food) {
    return 'Detected: $food';
  }

  @override
  String calories(int count) {
    return 'Calories: $count kcal';
  }

  @override
  String macros(String protein, String carbs, String fat) {
    return 'Protein: ${protein}g | Carbs: ${carbs}g | Fat: ${fat}g';
  }

  @override
  String advice(String text) {
    return 'Advice: $text';
  }

  @override
  String remainingBudget(int calories) {
    return 'Remaining: $calories kcal';
  }

  @override
  String overBudget(int calories) {
    return 'Over budget by $calories kcal!';
  }

  @override
  String get mealSaved => 'Meal saved! 🎉';

  @override
  String analysisFailed(String error) {
    return 'Analysis failed: $error';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get characterProgress => 'Character Progress';

  @override
  String levelAndClass(int level, String className) {
    return 'Level $level — $className';
  }

  @override
  String get attributes => 'Attributes';

  @override
  String get strength => 'Strength';

  @override
  String get intelligence => 'Intelligence';

  @override
  String get charisma => 'Charisma';

  @override
  String get vitality => 'Vitality';

  @override
  String get recentGains => 'Recent Gains';

  @override
  String get noGainsToday => 'No gains today. Complete your goals!';

  @override
  String get achievements => 'Achievements';

  @override
  String get noAchievements => 'No achievements yet. Keep going!';

  @override
  String get levelUp => 'LEVEL UP!';

  @override
  String levelUpMessage(int level) {
    return 'Congratulations! You reached Level $level!';
  }

  @override
  String newClass(String className) {
    return 'New Class: $className';
  }

  @override
  String get awesome => 'Awesome!';

  @override
  String get chatAssistant => 'Assistant';

  @override
  String get chatOnline => 'Online';

  @override
  String get chatHint => 'Type a message...';

  @override
  String get chatEmpty => 'Say hi to your AI life coach! 👋';

  @override
  String get apiKeyMissing =>
      'API key not configured. Please check your .env file.';

  @override
  String get homePage => 'Home';

  @override
  String get assistant => 'Assistant';

  @override
  String get scan => 'Scan';

  @override
  String get character => 'Character';

  @override
  String get social => 'Social';

  @override
  String get friends => 'Friends';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get addFriend => 'Add Friend';

  @override
  String get searchByEmail => 'Search by email';

  @override
  String get search => 'Search';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get requestSent => 'Friend request sent!';

  @override
  String get friendRequests => 'Friend Requests';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get noFriends => 'No friends yet. Add some!';

  @override
  String get weeklyXp => 'Weekly XP';

  @override
  String get streak => 'Streak';

  @override
  String get score => 'Score';

  @override
  String rank(int rank) {
    return '#$rank';
  }

  @override
  String get you => 'You';

  @override
  String get profile => 'Profile';

  @override
  String get signOut => 'Sign Out';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get name => 'Name';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';
}
