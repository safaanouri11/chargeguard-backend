import 'package:flutter/material.dart';
import 'app_settings.dart';

// ── Fixed Colors (always same) ────────────────────────────
const kGreen = Color(0xFF00E5A0);
const kRed   = Color(0xFFFF5C5C);

// ── Dark Colors ───────────────────────────────────────────
const kBg     = Color(0xFF0A0E1A);
const kCard   = Color(0xFF131929);
const kBorder = Color(0xFF1E2A3A);

// ── Light Colors ──────────────────────────────────────────
const kLightBg     = Color(0xFFF5F7FA);
const kLightCard   = Colors.white;
const kLightBorder = Color(0xFFE5E9F0);

// ═══════════════════════════════════════
//  DYNAMIC COLORS (theme-aware)
// ═══════════════════════════════════════
bool get _dark => AppSettings.instance.isDark;

Color get cBg     => _dark ? kBg     : kLightBg;
Color get cCard   => _dark ? kCard   : kLightCard;
Color get cBorder => _dark ? kBorder : kLightBorder;
Color get cTitle  => _dark ? Colors.white      : const Color(0xFF0D1B2A);
Color get cSub    => _dark ? Colors.white54    : Colors.black54;
Color get cSub2   => _dark ? Colors.white38    : Colors.black38;
Color get cNav    => _dark ? const Color(0xFF0F1520) : Colors.white;

// ═══════════════════════════════════════
//  TEXT STYLES
// ═══════════════════════════════════════
TextStyle kTitle(double size) =>
    TextStyle(color: cTitle, fontSize: size, fontWeight: FontWeight.w800);

TextStyle kSub(double size) =>
    TextStyle(color: cSub, fontSize: size);

// ═══════════════════════════════════════
//  DECORATIONS
// ═══════════════════════════════════════
BoxDecoration kCardDeco({double radius = 16}) => BoxDecoration(
      color: cCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cBorder),
    );

// ═══════════════════════════════════════
//  APP BAR
// ═══════════════════════════════════════
PreferredSizeWidget kAppBar(String title, BuildContext context,
    {bool showBack = true, List<Widget>? actions}) {
  return AppBar(
    backgroundColor: cBg,
    elevation: 0,
    automaticallyImplyLeading: showBack,
    leading: showBack
        ? IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cTitle),
            onPressed: () => Navigator.pop(context),
          )
        : null,
    title: Text(title, style: kTitle(18)),
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: cBorder),
    ),
  );
}

// ═══════════════════════════════════════
//  NAVIGATION HELPER
// ═══════════════════════════════════════
void goTo(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

// ═══════════════════════════════════════
//  SIMPLE PAGE TEMPLATE
// ═══════════════════════════════════════
class SimplePage extends StatelessWidget {
  final IconData icon;
  final String title, sub, btnLabel;
  final Color? color;
  final VoidCallback? onBtnTap;

  const SimplePage({
    super.key,
    required this.icon,
    required this.title,
    required this.sub,
    required this.btnLabel,
    this.color,
    this.onBtnTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? kGreen;
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar(title, context),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: c.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: c, size: 40),
          ),
          const SizedBox(height: 24),
          Text(title, style: kTitle(22), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(sub, style: kSub(14), textAlign: TextAlign.center),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: onBtnTap ?? () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: c, foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(btnLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}
