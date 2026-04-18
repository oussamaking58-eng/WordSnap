import 'package:flutter/material.dart';

import '../services/language_service.dart';
import '../services/score_service.dart';

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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF150A25), // Fond très sombre du sheet
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white12),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            
            // Profile Card
            _buildProfileCard(),
            const SizedBox(height: 30),

            // Language Selector
            Text(_langService.translate('language').toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildLangButton('FR', AppLanguage.fr),
                const SizedBox(width: 10),
                _buildLangButton('EN', AppLanguage.en),
                const SizedBox(width: 10),
                _buildLangButton('العربية', AppLanguage.ar),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Toggles
            Text(_langService.translate('settings').toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            _buildToggle(_langService.translate('sound'), _soundEnabled, (v) => setState(() => _soundEnabled = v)),
            _buildToggle(_langService.translate('haptics'), _hapticsEnabled, (v) => setState(() => _hapticsEnabled = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: const Text('👤', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Player 1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                Text('🔥 ${ScoreService().streak} ${_langService.translate('streak')}', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLangButton(String label, AppLanguage lang) {
    bool isActive = _langService.currentLanguage == lang;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() { _langService.setLanguage(lang); });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).colorScheme.tertiary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? Theme.of(context).colorScheme.tertiary : Colors.transparent),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Theme.of(context).colorScheme.tertiary : Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
