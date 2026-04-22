import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/language_service.dart';
import '../services/score_service.dart';
import '../theme/app_theme.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final LanguageService _langService = LanguageService();
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _langService.addListener(_rebuild);
  }

  @override
  void dispose() {
    _langService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 15, top: 10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  _langService.translate('settings').toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4),
                ),
                const SizedBox(height: 20),
                
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Profile Section
                          _buildProfileSection(),
                          const SizedBox(height: 35),

                          // Settings Section
                          _buildSectionHeader("${_langService.translate('sound').toUpperCase()} & ${_langService.translate('haptics').toUpperCase()}"),
                          const SizedBox(height: 12),
                          _buildToggleItem(Icons.volume_up_rounded, _langService.translate('sound').toUpperCase(), _soundEnabled, (v) => setState(() => _soundEnabled = v)),
                          _buildToggleItem(Icons.vibration_rounded, _langService.translate('haptics').toUpperCase(), _hapticsEnabled, (v) => setState(() => _hapticsEnabled = v)),
                          
                          const SizedBox(height: 25),

                          // Language Section
                          _buildSectionHeader(_langService.translate('language').toUpperCase()),
                          const SizedBox(height: 12),
                          _buildLanguageSelector(),
                          
                          const SizedBox(height: 25),

                          // Account & Legal
                          _buildSectionHeader(_langService.translate('account').toUpperCase()),
                          const SizedBox(height: 12),
                          _buildSimpleItem(_langService.translate('notifications').toUpperCase()),
                          _buildSimpleItem(_langService.translate('cloud_sync').toUpperCase()),
                          
                          const SizedBox(height: 25),
                          
                          _buildSectionHeader(_langService.translate('legal').toUpperCase()),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSmallLink(_langService.translate('privacy')),
                              const SizedBox(width: 20),
                              _buildSmallLink(_langService.translate('terms')),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Log Out Button
                          _buildLogoutButton(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Glass Card
        Container(
          margin: const EdgeInsets.only(top: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(color: AppColors.purple.withValues(alpha: 0.1), blurRadius: 30),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                color: Colors.white.withValues(alpha: 0.05),
                child: Column(
                  children: [
                    const Text(
                      'Player 1',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_langService.translate('joined')}: Dec 2023',
                      style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${_langService.translate('total_streak')}: ', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold)),
                        const Text('🔥', style: TextStyle(fontSize: 18)),
                        Text(
                          ' ${ScoreService().streak}',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Avatar
        Positioned(
          top: 0,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F021A),
              border: Border.all(color: AppColors.cyan, width: 3),
              boxShadow: [
                BoxShadow(color: AppColors.cyan.withValues(alpha: 0.4), blurRadius: 20),
              ],
            ),
            child: const Center(
              child: Text(
                'P1',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem(IconData icon, String label, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: value ? AppColors.cyan.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white.withValues(alpha: 0.03),
            child: Row(
              children: [
                Icon(icon, color: value ? AppColors.cyan : Colors.white70, size: 20),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const Spacer(),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.cyan,
                  activeTrackColor: AppColors.cyan.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white24,
                  inactiveTrackColor: Colors.white10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.purple.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white.withValues(alpha: 0.03),
            child: Row(
              children: [
                _buildLangOption('🇺🇸 EN', AppLanguage.en),
                _buildLangOption('🇫🇷 FR', AppLanguage.fr),
                _buildLangOption('🇹🇳 AR', AppLanguage.ar),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangOption(String label, AppLanguage lang) {
    bool isActive = _langService.currentLanguage == lang;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await _langService.setLanguage(lang);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.cyan.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isActive ? AppColors.cyan : Colors.transparent),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleItem(String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: Colors.white.withValues(alpha: 0.03),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallLink(String label) {
    return Text(
      label,
      style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: AppColors.red.withValues(alpha: 0.05),
            child: Center(
              child: Text(
                _langService.translate('logout').toUpperCase(),
                style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
