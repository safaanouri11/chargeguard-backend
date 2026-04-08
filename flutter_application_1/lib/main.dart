import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'utils/app_settings.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/host_dashboard_screen.dart';

void main() => runApp(const ChargeGuardApp());

// ═══════════════════════════════════════
//  APP — listens to AppSettings
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

  // ── Dark Theme ────────────────────────
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

  // ── Light Theme ───────────────────────
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
      // اتجاه النص حسب اللغة
      builder: (context, child) => Directionality(
        textDirection: _s.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash':   (context) => const SplashScreen(),
        '/login':    (context) => const LoginScreen(),
        '/register': (context) => const SignupScreen(),
        '/home':     (context) => const MainShell(),
        '/host':     (context) => const HostDashboardScreen(),
      },
    );
  }
}

// ═══════════════════════════════════════
//  SPLASH SCREEN
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
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
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
    ProfileScreen(),
  ];

  static const _nav = [
    {'icon': Icons.home_outlined,          'active': Icons.home,           'label': 'Home'},
    {'icon': Icons.map_outlined,            'active': Icons.map,            'label': 'Map'},
    {'icon': Icons.calendar_today_outlined, 'active': Icons.calendar_today, 'label': 'Bookings'},
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
