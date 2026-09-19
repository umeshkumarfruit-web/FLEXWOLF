import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/utils/app_haptics.dart';
import 'package:flexwolf/features/home/app_section.dart';
import 'package:flutter/material.dart';

class AppMainNavigationBar extends StatelessWidget {
  const AppMainNavigationBar({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const sections = [
    AppSection.home,
    AppSection.shop,
    AppSection.support,
    AppSection.account,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: NavigationBar(
          selectedIndex: sections
              .indexWhere((s) => s.index == currentIndex)
              .clamp(0, sections.length - 1),
          onDestinationSelected: (index) {
            final branchIndex = sections[index].index;
            if (branchIndex != currentIndex) {
              AppHaptics.selection();
            }
            onDestinationSelected(branchIndex);
          },
          destinations: [
            for (final section in sections)
              NavigationDestination(
                icon: Icon(section.icon),
                selectedIcon: Icon(section.selectedIcon),
                label: section.label,
              ),
          ],
        ),
      ),
    );
  }
}
