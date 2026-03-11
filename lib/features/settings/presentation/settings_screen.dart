import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.close, color: AppColors.textPrimary),
        ),
        title: const Text('설정', style: AppTypography.h2),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        children: [
          _SettingsSection(
            title: '카메라',
            items: [
              _SettingsItem(
                icon: Icons.save_alt_outlined,
                label: '갤러리 자동 저장',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.silver,
                  inactiveTrackColor: AppColors.border,
                ),
              ),
              _SettingsItem(
                icon: Icons.vibration,
                label: '햅틱 피드백',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.silver,
                  inactiveTrackColor: AppColors.border,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceL),
          _SettingsSection(
            title: '정보',
            items: [
              _SettingsItem(
                icon: Icons.info_outline,
                label: '버전',
                trailing: const Text('1.0.0', style: AppTypography.bodySmall),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.spaceS,
            bottom: AppDimensions.spaceS,
          ),
          child: Text(title.toUpperCase(), style: AppTypography.caption),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.trailing,
  });
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceM,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.silver, size: AppDimensions.iconSize),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(child: Text(label, style: AppTypography.body)),
          trailing,
        ],
      ),
    );
  }
}
