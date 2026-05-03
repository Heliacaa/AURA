// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'AURA';

  @override
  String get goodMorning => 'Günaydın';

  @override
  String get goodAfternoon => 'İyi günler';

  @override
  String get goodEvening => 'İyi akşamlar';

  @override
  String get dailyScore => 'Günlük Skor';

  @override
  String steps(int count) {
    return '$count Adım';
  }

  @override
  String get stepGoalReached => 'Hedefe ulaştın! 🎉';

  @override
  String get stepGoalAlmost => 'Hedefe az kaldı!';

  @override
  String get stepGoalGood => 'İyi gidiyorsun!';

  @override
  String get stepGoalStart => 'Haydi harekete geç! 💪';

  @override
  String socialEnergy(String level) {
    return 'Sosyal Enerji: $level';
  }

  @override
  String get energyHigh => 'Enerjin harika! Sosyalleş!';

  @override
  String get energyMedium => 'Dengeli bir gün.';

  @override
  String get energyLow => 'Biraz dinlenmelisin.';

  @override
  String streakDays(int count) {
    return '$count Günlük Seri';
  }

  @override
  String waterProgress(int current, int goal) {
    return '$current / $goal Bardak Su';
  }

  @override
  String get waterGoalReached => 'Hedefe ulaştın! 🎉';

  @override
  String get waterDrinkMore => 'Daha fazla su iç!';

  @override
  String get updateSteps => 'Adım Güncelle';

  @override
  String get stepCount => 'Adım sayısı';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String error(String message) {
    return 'Hata: $message';
  }

  @override
  String get weeklyTrends => 'Haftalık Trendler';

  @override
  String get dailyQuests => 'Günlük Görevler';

  @override
  String dailyQuestProgress(int completed, int total) {
    return '$completed / $total ödül alındı';
  }

  @override
  String get dailyQuestClaim => 'Al';

  @override
  String get dailyQuestClaimed => 'Alındı';

  @override
  String get dailyQuestLocked => 'Kilitli';

  @override
  String get dailyQuestRewardClaimed => 'Görev ödülü alındı!';

  @override
  String get dailyQuestAlreadyClaimed => 'Bu görev zaten alındı.';

  @override
  String dailyQuestClaimFailed(String error) {
    return 'Görev alınamadı: $error';
  }

  @override
  String get sleepQuestTitle => 'Uyku Kaydı';

  @override
  String get sleepQuestSubtitle => 'Gece uykunu kaydet';

  @override
  String get mealQuestTitle => 'Yemek Kaydı';

  @override
  String get mealQuestSubtitle => 'En az 1 öğün tarayıp kaydet';

  @override
  String get waterQuestTitle => 'Su Hedefi';

  @override
  String get waterQuestSubtitle => 'Günlük su hedefini tamamla';

  @override
  String get stepsQuestTitle => 'Adım Hedefi';

  @override
  String get stepsQuestSubtitle => 'Günlük adım hedefini tamamla';

  @override
  String get sleepCard => 'Uyku';

  @override
  String sleepHours(String hours) {
    return '${hours}s uyku';
  }

  @override
  String get sleepQualityGood => 'İyi';

  @override
  String get sleepQualityFair => 'Orta';

  @override
  String get sleepQualityPoor => 'Kötü';

  @override
  String get logSleep => 'Uyku Kaydet';

  @override
  String get sleepHoursLabel => 'Uyunan saat';

  @override
  String get sleepQuality => 'Uyku Kalitesi';

  @override
  String get macroSummary => 'Bugünün Beslenmesi';

  @override
  String caloriesOf(int consumed, int goal) {
    return '$consumed / $goal kcal';
  }

  @override
  String get proteinLabel => 'Protein';

  @override
  String get carbsLabel => 'Karbonhidrat';

  @override
  String get fatLabel => 'Yağ';

  @override
  String get aiVisionScan => 'AI Vision Tarama';

  @override
  String get tapToTakePhoto => 'Yemek fotoğrafı çekmek için dokun';

  @override
  String get takePhoto => 'Fotoğraf Çek';

  @override
  String get chooseFromGallery => 'Galeriden Seç';

  @override
  String get analyzingFood => 'Yemek analiz ediliyor...';

  @override
  String get scanResults => 'Tarama Sonuçları';

  @override
  String detected(String food) {
    return 'Tespit Edildi: $food';
  }

  @override
  String calories(int count) {
    return 'Kalori: $count kcal';
  }

  @override
  String macros(String protein, String carbs, String fat) {
    return 'Protein: ${protein}g | Karb: ${carbs}g | Yağ: ${fat}g';
  }

  @override
  String advice(String text) {
    return 'Tavsiye: $text';
  }

  @override
  String remainingBudget(int calories) {
    return 'Kalan: $calories kcal';
  }

  @override
  String overBudget(int calories) {
    return 'Bütçeyi $calories kcal aştın!';
  }

  @override
  String get mealSaved => 'Yemek kaydedildi! 🎉';

  @override
  String analysisFailed(String error) {
    return 'Analiz başarısız: $error';
  }

  @override
  String saveFailed(String error) {
    return 'Kayıt başarısız: $error';
  }

  @override
  String get characterProgress => 'Karakter Gelişimi';

  @override
  String levelAndClass(int level, String className) {
    return 'Level $level — $className';
  }

  @override
  String get attributes => 'Özellikler';

  @override
  String get strength => 'Güç';

  @override
  String get intelligence => 'Zeka';

  @override
  String get charisma => 'Karizma';

  @override
  String get vitality => 'Vitalite';

  @override
  String get recentGains => 'Son Kazanımlar';

  @override
  String get noGainsToday => 'Bugün henüz kazanım yok. Hedeflerini tamamla!';

  @override
  String get achievements => 'Başarımlar';

  @override
  String get noAchievements => 'Henüz başarım yok. Devam et!';

  @override
  String get levelUp => 'SEVİYE ATLADI!';

  @override
  String levelUpMessage(int level) {
    return 'Tebrikler! Seviye $level\'e ulaştın!';
  }

  @override
  String newClass(String className) {
    return 'Yeni Sınıf: $className';
  }

  @override
  String get awesome => 'Harika!';

  @override
  String get chatAssistant => 'Asistan';

  @override
  String get chatOnline => 'Çevrimiçi';

  @override
  String get chatHint => 'Mesaj yaz...';

  @override
  String get chatEmpty => 'AI yaşam koçuna merhaba de! 👋';

  @override
  String get apiKeyMissing =>
      'API anahtarı yapılandırılmamış. .env dosyasına GEMINI_API_KEY ekle veya --dart-define=GEMINI_API_KEY=YOUR_KEY ile çalıştır.';

  @override
  String get homePage => 'Ana Sayfa';

  @override
  String get assistant => 'Asistan';

  @override
  String get scan => 'Tarama';

  @override
  String get character => 'Karakter';

  @override
  String get social => 'Sosyal';

  @override
  String get friends => 'Arkadaşlar';

  @override
  String get leaderboard => 'Sıralama';

  @override
  String get addFriend => 'Arkadaş Ekle';

  @override
  String get searchByEmail => 'E-posta ile ara';

  @override
  String get search => 'Ara';

  @override
  String get sendRequest => 'İstek Gönder';

  @override
  String get requestSent => 'Arkadaşlık isteği gönderildi!';

  @override
  String get friendRequests => 'Arkadaşlık İstekleri';

  @override
  String get accept => 'Kabul Et';

  @override
  String get decline => 'Reddet';

  @override
  String get noFriends => 'Henüz arkadaş yok. Birilerini ekle!';

  @override
  String get weeklyXp => 'Haftalık XP';

  @override
  String get weeklyLeague => 'Weekly League';

  @override
  String get friendsRanking => 'Arkadaşlar';

  @override
  String get weeklyLeagueActive => 'Weekly League aktif';

  @override
  String get weeklyLeagueInactive => 'Weekly League kapalı';

  @override
  String weeklyLeagueActiveSubtitle(int xp) {
    return 'Bu hafta $xp XP ile sıralamadasın.';
  }

  @override
  String get weeklyLeagueInactiveSubtitle =>
      'Haftalık XP sıralamasında görünmek için katıl.';

  @override
  String get weeklyLeagueEmpty =>
      'Bu haftanın liginde henüz kimse yok. İlk katılan sen olabilirsin.';

  @override
  String get weeklyLeagueEnabled => 'Weekly League görünürlüğü açıldı.';

  @override
  String get weeklyLeagueDisabled => 'Weekly League görünürlüğü kapatıldı.';

  @override
  String weeklyLeagueUpdateFailed(String error) {
    return 'Sıralama güncellenemedi: $error';
  }

  @override
  String get streak => 'Seri';

  @override
  String get score => 'Skor';

  @override
  String rank(int rank) {
    return '#$rank';
  }

  @override
  String get you => 'Sen';

  @override
  String get profile => 'Profil';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get login => 'Giriş Yap';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get confirmPassword => 'Şifre Tekrar';

  @override
  String get name => 'İsim';

  @override
  String get signInWithGoogle => 'Google ile Giriş Yap';

  @override
  String get dontHaveAccount => 'Hesabın yok mu?';

  @override
  String get alreadyHaveAccount => 'Zaten hesabın var mı?';
}
