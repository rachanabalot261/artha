import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sms_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends ConsumerState<SettingsScreen> {
  bool _importing = false;

  Future<void> _importSms() async {
    setState(() => _importing = true);
    final n = await SmsService.instance.importInbox();
    if (!mounted) return;
    setState(() => _importing = false);
    refreshAll(ref); // refresh all screens with new data
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(n > 0
          ? '✓ $n transactions imported from SMS'
          : 'No new transactions found'),
      backgroundColor:
          n > 0 ? AppColors.income : AppColors.expense,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy status banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.income.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined,
                    color: AppColors.income, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('100% Private',
                          style: TextStyle(
                              color: AppColors.income,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text(
                        'Encrypted database • Biometric lock • No cloud',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const _SectionLabel('Data Import'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.sms_outlined,
              color: AppColors.purple,
              title: 'Import from SMS',
              subtitle:
                  'Scan UPI transaction SMS (last 12 months)',
              trailing: _importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.purple))
                  : const Icon(Icons.chevron_right,
                      color: AppColors.textMuted),
              onTap: _importing ? null : _importSms,
            ),
            const _Divider(),
            _SettingsTile(
              icon: Icons.upload_file_outlined,
              color: AppColors.saving,
              title: 'Import CSV',
              subtitle: 'Bank statement CSV file',
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textMuted),
              onTap: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(
                      content: Text('CSV import — coming soon'))),
            ),
          ]),

          const SizedBox(height: 24),
          const _SectionLabel('Security'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.lock_outlined,
              color: AppColors.expense,
              title: 'Lock Now',
              subtitle: 'Require biometric to reopen',
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textMuted),
              onTap: () =>
                  ref.read(appStateProvider.notifier).lock(),
            ),
            const _Divider(),
            const _SettingsTile(
              icon: Icons.timer_outlined,
              color: AppColors.warning,
              title: 'Auto-lock',
              subtitle:
                  'Locks after 30 seconds in background',
              trailing: Icon(Icons.check_circle_outline,
                  color: AppColors.income, size: 20),
            ),
            const _Divider(),
            const _SettingsTile(
              icon: Icons.storage_outlined,
              color: AppColors.income,
              title: 'Database Encryption',
              subtitle: 'AES-256 via SQLCipher • Hardware key',
              trailing: Icon(Icons.check_circle_outline,
                  color: AppColors.income, size: 20),
            ),
          ]),

          const SizedBox(height: 24),
          const _SectionLabel('AI'),
          const _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.psychology_outlined,
              color: AppColors.purple,
              title: 'Model',
              subtitle: 'Phi-3 Mini via Ollama (local network)',
              trailing: null,
            ),
            _Divider(),
            _SettingsTile(
              icon: Icons.wifi_outlined,
              color: AppColors.saving,
              title: 'Privacy',
              subtitle:
                  'Queries processed on your home network only',
              trailing: Icon(Icons.check_circle_outline,
                  color: AppColors.income, size: 20),
            ),
          ]),

          const SizedBox(height: 24),
          const _SectionLabel('About'),
          const _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.info_outline,
              color: AppColors.textMuted,
              title: 'Artha v1.0.0',
              subtitle:
                  'Flutter • SQLCipher • Riverpod • Phi-3 Mini',
              trailing: null,
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 12)),
      trailing: trailing,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 0, indent: 68, endIndent: 16);
  }
}