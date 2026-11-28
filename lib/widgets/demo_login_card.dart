import 'package:flutter/material.dart';

import '../utils/colors.dart';

// Demo builds pass these with --dart-define (see the documentation).
// They are empty in normal builds, so nothing is shown.
const demoOwnerEmail = String.fromEnvironment('DEMO_EMAIL');
const demoOwnerPassword = String.fromEnvironment('DEMO_PASSWORD');
const demoStaffPin = String.fromEnvironment('DEMO_STAFF_PIN');
const demoStaffPassword = String.fromEnvironment('DEMO_STAFF_PASSWORD');

/// Shows demo login details on the sign-in screens of a demo build.
class DemoLoginCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  const DemoLoginCard({super.key, required this.title, required this.lines});

  static Widget? owner() => demoOwnerEmail.isEmpty
      ? null
      : const DemoLoginCard(
          title: "Demo owner login",
          lines: ["Email: $demoOwnerEmail", "Password: $demoOwnerPassword"]);

  static Widget? staff() => demoStaffPin.isEmpty
      ? null
      : const DemoLoginCard(
          title: "Demo staff login",
          lines: ["PIN: $demoStaffPin", "Password: $demoStaffPassword"]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mainColor.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.mainColor)),
          const SizedBox(height: 4),
          for (final l in lines)
            SelectableText(l,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}
