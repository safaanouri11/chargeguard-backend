import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'utils/app_settings.dart';
import 'utils/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/host_dashboard_screen.dart';
import 'screens/host_pending_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/welcome_back_screen.dart';
import 'utils/biometric.dart';
import 'utils/storage.dart';

void main() => runApp(const ChargeGuardApp());

// ═══════════════════════════════════════
//  APP
// ═══════════════════════════════════════
class ChargeGuardApp extends StatefulWidget {
  const ChargeGuardApp({super.key});
  @override
  State<ChargeGuardApp> createState() => _ChargeGuardAppState();
}

class _ChargeGuardAppState extends State<ChargeGuardApp> {
  final _s = AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _s.addListener(_refresh);
  }

  @override
  void dispose() {
    _s.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  ThemeData get _dark => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: kBg,
    colorScheme: const ColorScheme.dark(primary: kGreen, surface: kCard),
    appBarTheme: const AppBarTheme(
        backgroundColor: kBg, foregroundColor: Colors.white, elevation: 0),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? kGreen : Colors.white38),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? kGreen.withOpacity(0.3) : kBorder),
    ),
  );

  ThemeData get _light => ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    colorScheme: const ColorScheme.light(primary: kGreen, surface: Colors.white),
    appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? kGreen : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? kGreen.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChargeGuard',
      debugShowCheckedModeBanner: false,
      theme:     _light,
      darkTheme: _dark,
      themeMode: _s.themeMode,
      builder: (context, child) => Directionality(
        textDirection: _s.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash':        (context) => const SplashScreen(),
        '/login':         (context) => const LoginScreen(),
        '/welcome-back':  (context) => const WelcomeBackScreen(),
        '/register':      (context) => const SignupScreen(),
        '/home':          (context) => const MainShell(),
        '/host':          (context) => const HostDashboardScreen(),
        '/host-pending':  (context) => const HostPendingScreen(),
        '/admin':         (context) => const AdminDashboardScreen(),
      },
    );
  }
}

// ═══════════════════════════════════════
//  SPLASH — Auto Login من localStorage
// ═══════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 1. Biometric gate — if the user previously enabled it and we have a
    //    saved token, require a successful biometric before auto-login.
    final hasToken = (await Storage.get('cg_token')) != null;
    if (hasToken && await Biometric.isEnabled()) {
      final available = await Biometric.available();
      if (available) {
        final ok = await Biometric.authenticate(
            reason: 'Sign in to ChargeGuard');
        if (!ok) {
          // Biometric failed/cancelled — fall through to Welcome Back.
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/welcome-back');
          return;
        }
      }
    }

    // 2. Standard auto-login path (Remember Me was on)
    final ok = await ApiService.instance.tryAutoLogin();
    if (!mounted) return;
    if (ok) {
      _routeByRole();
      return;
    }

    // 3. No active session — but maybe we know who the user was.
    //    Show Welcome Back so they only need their password.
    final lastUser = await Storage.get('cg_last_user');
    if (!mounted) return;
    if (lastUser != null) {
      Navigator.pushReplacementNamed(context, '/welcome-back');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _routeByRole() {
    final user = UserSession.instance;
    final role = user.role;
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (role == 'host') {
      final status = user.user?['hostStatus'] as String? ?? 'Approved';
      Navigator.pushReplacementNamed(
          context, status == 'Approved' ? '/host' : '/host-pending');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Center(
      child: FadeTransition(
        opacity: _fade,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.12), shape: BoxShape.circle,
              border: Border.all(color: kGreen.withOpacity(0.5), width: 2),
            ),
            child: const Icon(Icons.ev_station, color: kGreen, size: 52),
          ),
          const SizedBox(height: 24),
          Text('ChargeGuard', style: kTitle(30)),
          const SizedBox(height: 8),
          Text('Find. Book. Charge.', style: kSub(15)),
          const SizedBox(height: 24),
          const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: kGreen, strokeWidth: 2)),
        ]),
      ),
    ),
  );
}

// ═══════════════════════════════════════
//  MAIN SHELL — Bottom Navigation
// ═══════════════════════════════════════
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    MapScreen(),
    BookingsScreen(),
    BookmarksScreen(),
    ProfileScreen(),
  ];

  static const _nav = [
    {'icon': Icons.home_outlined,          'active': Icons.home,           'label': 'Home'},
    {'icon': Icons.map_outlined,            'active': Icons.map,            'label': 'Map'},
    {'icon': Icons.calendar_today_outlined, 'active': Icons.calendar_today, 'label': 'Bookings'},
    {'icon': Icons.bookmark_outline,        'active': Icons.bookmark,       'label': 'Saved'},
    {'icon': Icons.person_outline,          'active': Icons.person,         'label': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1520),
          border: Border(top: BorderSide(color: kBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_nav.length, (i) {
            final sel  = _idx == i;
            final item = _nav[i];
            return GestureDetector(
              onTap: () => setState(() => _idx = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? kGreen.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    sel ? item['active'] as IconData : item['icon'] as IconData,
                    color: sel ? kGreen : Colors.white38, size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(item['label'] as String,
                      style: TextStyle(
                          color: sel ? kGreen : Colors.white38, fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }
}
