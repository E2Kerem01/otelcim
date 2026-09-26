import 'package:flutter/material.dart';

import '../../shared/widgets/desktop_top_nav_bar.dart';

/// Adds the desktop navigation chrome to root-level pages without changing
/// the mobile page tree.
class DesktopPageFrame extends StatelessWidget {
  const DesktopPageFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 768) return child;

        return Column(
          children: [
            const DesktopTopNavBar(),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
