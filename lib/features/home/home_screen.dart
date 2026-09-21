import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../shared/activity_button.dart';
import '../plans/activity.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text('CiaMaFa?', style: text.displayLarge),
            Text(
              'Lancia un piano al gruppo.',
              style: text.titleMedium?.copyWith(color: AppColors.coralText),
            ),
            const SizedBox(height: 28),
            for (final activity in activities) ...[
              ActivityButton(
                activity: activity,
                onTap: (origin) =>
                    context.push('/places/${activity.id}', extra: origin),
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}
