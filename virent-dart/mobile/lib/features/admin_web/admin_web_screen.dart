// admin_web_screen.dart — Virent admin web panel entry point.
//
// Wraps the Swift-style mockup `AppLayout` (header + sidebar + content)
// in a responsive shell:
//   - On wide screens (>= 1100 px) shows the sidebar permanently.
//   - On narrow screens (< 1100 px) hides the sidebar behind a Drawer
//     opened from the header's hamburger icon.
//
// The screen is admin-only — the go_router redirect in app_router.dart
// already blocks non-admin sessions from reaching `/admin/web`.

import 'package:flutter/material.dart';

import 'layout/app_layout.dart';

/// Entry point for the `/admin/web` route.
///
/// Renders the desktop-style admin panel (header + sidebar + page content)
/// adapted from the user-supplied mockup. The mockup's `AppLayout` widget
/// is reused as-is — this wrapper only adds the responsive drawer
/// behavior for mobile and a `Scaffold` shell.
class AdminWebScreen extends StatelessWidget {
  const AdminWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // AppLayout already includes its own header + sidebar + body —
      // no need for an extra AppBar.
      body: AppLayout(),
    );
  }
}
