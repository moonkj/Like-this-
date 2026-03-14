import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/preferences_service.dart';
import '../../../l10n/l10n_ext.dart';
import 'policy_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        ),
        title: Text(context.l10n.settings, style: AppTypography.h2),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        children: [
          _SettingsSection(
            title: context.l10n.cameraSection,
            items: [
              _SettingsItem(
                icon: Icons.volume_off_outlined,
                label: context.l10n.silentShutter,
                subtitle: context.l10n.silentShutterDesc,
                trailing: Switch(
                  // 무음 셔터 ON = shutterSound false (소리 안 냄)
                  value: !prefs.shutterSound,
                  onChanged: (v) => notifier.setShutterSound(!v),
                  activeThumbColor: AppColors.silver,
                  inactiveTrackColor: AppColors.border,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceL),
          _SettingsSection(
            title: context.l10n.appInfo,
            items: [
              _SettingsItem(
                icon: Icons.info_outline,
                label: context.l10n.version,
                trailing: const Text('1.0.0', style: AppTypography.bodySmall),
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                label: context.l10n.privacyPolicy,
                trailing: const Icon(Icons.chevron_right, color: AppColors.silver, size: 20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PolicyScreen.privacyPolicy),
                ),
              ),
              _SettingsItem(
                icon: Icons.description_outlined,
                label: context.l10n.termsOfService,
                trailing: const Icon(Icons.chevron_right, color: AppColors.silver, size: 20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PolicyScreen.termsOfService),
                ),
              ),
              _SettingsItem(
                icon: Icons.mail_outline,
                label: context.l10n.contact,
                trailing: const Icon(Icons.chevron_right, color: AppColors.silver, size: 20),
                onTap: () => launchUrl(
                  Uri.parse('mailto:imurmkj@gmail.com?subject=Like This! 문의'),
                  mode: LaunchMode.externalApplication,
                ),
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
          child: Text(title, style: AppTypography.caption),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(height: 1, indent: 48, color: AppColors.border),
              ],
            ],
          ),
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
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: AppDimensions.spaceM,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.silver, size: AppDimensions.iconSize),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.body),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.caption),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
