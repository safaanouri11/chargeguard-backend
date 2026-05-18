import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  // ── Theme ─────────────────────────────
  bool _isDark = true;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // ── Language ──────────────────────────
  bool _isArabic = false;
  bool get isArabic => _isArabic;
  String get langCode => _isArabic ? 'ar' : 'en';

  void toggleLanguage() {
    _isArabic = !_isArabic;
    notifyListeners();
  }

  // ── Notifications ─────────────────────
  bool _chargingDone    = true;
  bool _bookingReminder = true;
  bool _offers          = true;
  bool _lowBattery      = false;

  bool get chargingDone    => _chargingDone;
  bool get bookingReminder => _bookingReminder;
  bool get offers          => _offers;
  bool get lowBattery      => _lowBattery;

  void toggleChargingDone()    { _chargingDone    = !_chargingDone;    notifyListeners(); }
  void toggleBookingReminder() { _bookingReminder = !_bookingReminder; notifyListeners(); }
  void toggleOffers()          { _offers          = !_offers;          notifyListeners(); }
  void toggleLowBattery()      { _lowBattery      = !_lowBattery;      notifyListeners(); }
}

// ══════════════════════════════════════════
//  TRANSLATIONS
// ══════════════════════════════════════════
class L {
  static bool get _ar => AppSettings.instance.isArabic;

  static String get appName       => 'ChargeGuard';
  static String get home          => _ar ? 'الرئيسية'    : 'Home';
  static String get map           => _ar ? 'الخريطة'     : 'Map';
  static String get bookings      => _ar ? 'الحجوزات'    : 'Bookings';
  static String get profile       => _ar ? 'الملف الشخصي': 'Profile';
  static String get welcome       => _ar ? 'مرحباً 👋'   : 'Hello 👋';
  static String get dashboard     => _ar ? 'لوحة التحكم' : 'Dashboard';
  static String get nearestSt     => _ar ? 'أقرب المحطات': 'Nearest Stations';
  static String get seeAll        => _ar ? 'عرض الكل'    : 'See all';
  static String get quickActions  => _ar ? 'إجراءات سريعة': 'Quick Actions';
  static String get findCharger   => _ar ? 'ابحث\nشاحن'  : 'Find\nCharger';
  static String get myBookings    => _ar ? 'حجوزاتي'     : 'My\nBookings';
  static String get startCharge   => _ar ? 'ابدأ\nالشحن'  : 'Start\nCharge';
  static String get history       => _ar ? 'السجل'       : 'History';
  static String get available     => _ar ? 'متاح'        : 'Available';
  static String get busy          => _ar ? 'مشغول'       : 'Busy';
  static String get batteryStatus => _ar ? 'حالة البطارية': 'Battery Status';
  static String get settings      => _ar ? 'الإعدادات'   : 'Settings';
  static String get language      => _ar ? 'اللغة'       : 'Language';
  static String get theme         => _ar ? 'المظهر'      : 'Theme';
  static String get darkMode      => _ar ? 'الوضع الداكن': 'Dark Mode';
  static String get lightMode     => _ar ? 'الوضع الفاتح': 'Light Mode';
  static String get notifications => _ar ? 'الإشعارات'   : 'Notifications';
  static String get logout        => _ar ? 'تسجيل خروج'  : 'Logout';
  static String get offers        => _ar ? 'العروض'      : 'Offers';
  static String get chargingNow   => _ar ? 'يشحن الآن'   : 'Charging Now';
  static String get stop          => _ar ? 'إيقاف'       : 'Stop';
  static String get recentBook    => _ar ? 'آخر الحجوزات' : 'Recent Bookings';
  static String get viewAll       => _ar ? 'عرض الكل'    : 'View all';
  static String get myProfile     => _ar ? 'ملفي الشخصي' : 'My Profile';
  static String get editProfile   => _ar ? 'تعديل الملف' : 'Edit Profile';
  static String get saveChanges   => _ar ? 'حفظ التغييرات': 'Save Changes';
  static String get appearance    => _ar ? 'المظهر'      : 'Appearance';
  static String get security      => _ar ? 'الأمان'      : 'Security';
  static String get about         => _ar ? 'عن التطبيق'  : 'About';
  static String get changePass    => _ar ? 'تغيير كلمة المرور': 'Change Password';
  static String get deleteAccount => _ar ? 'حذف الحساب'  : 'Delete Account';
  static String get upcoming      => _ar ? 'قادم'        : 'Upcoming';
  static String get completed     => _ar ? 'مكتمل'       : 'Completed';
  static String get cancelled     => _ar ? 'ملغى'        : 'Cancelled';

  // ── Login screen ───────────────────────────────────────
  static String get welcomeBack    => _ar ? 'مرحباً بعودتك!'      : 'Welcome Back!';
  static String get loginSubtitle  => _ar ? 'سجّل دخول لتكمل الشحن' : 'Login to continue charging';
  static String get emailAddress   => _ar ? 'البريد الإلكتروني'   : 'Email Address';
  static String get emailHint      => _ar ? 'مثال@email.com'      : 'example@email.com';
  static String get password       => _ar ? 'كلمة المرور'         : 'Password';
  static String get passwordHint   => _ar ? 'أدخل كلمة المرور'    : 'Enter your password';
  static String get rememberMe     => _ar ? 'تذكّرني'             : 'Remember me';
  static String get forgotPassword => _ar ? 'نسيت كلمة المرور؟'   : 'Forgot password?';
  static String get login          => _ar ? 'تسجيل الدخول'        : 'Login';
  static String get imCharger      => _ar ? 'أنا صاحب شاحن'        : "I'm a Charger Host";
  static String get noAccount      => _ar ? 'ما عندك حساب؟ '       : "Don't have an account? ";
  static String get signUp         => _ar ? 'سجّل الآن'           : 'Sign Up';
  static String get becomeHost     => _ar ? 'كن مضيفاً ←'         : 'Become a Host →';
  static String get enterEmailPass => _ar ? 'الرجاء إدخال البريد وكلمة المرور' : 'Please enter email and password';
  static String get invalidEmail   => _ar ? 'بريد إلكتروني غير صالح' : 'Enter a valid email address';
  static String get invalidLogin   => _ar ? 'بريد أو كلمة مرور غير صحيحة' : 'Invalid email or password';
  static String get connectionError=> _ar ? 'خطأ في الاتصال'      : 'Connection error';
}
