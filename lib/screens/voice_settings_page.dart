import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/widgets/app_background.dart';

class VoiceSettingsPage extends StatelessWidget {
  const VoiceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Voice Settings',
          style: context.textStyles.titleLarge?.copyWith(color: Colors.white),
        ),
      ),
      body: AppGradientBackground(
        child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.brownCard,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Recognition',
                    style: context.textStyles.titleMedium?.copyWith(color: Colors.white),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Voice recognition is enabled for the AI Assistant. You can use voice commands to set travel alerts and get notifications when you\'re near specific locations.',
                    style: context.textStyles.bodyMedium?.copyWith(color: AppColors.lightGray),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Example Commands:',
                    style: context.textStyles.bodyMedium?.copyWith(color: AppColors.golden),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '• "Alert me when I\'m near Majestic within 500m"',
                    style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray),
                  ),
                  Text(
                    '• "Notify me near MG Road within 1000m"',
                    style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
